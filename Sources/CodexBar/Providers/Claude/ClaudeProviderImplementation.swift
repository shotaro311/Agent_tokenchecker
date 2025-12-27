import CodexBarCore
import Foundation

struct ClaudeUsageStrategy: Equatable, Sendable {
    let dataSource: ClaudeUsageDataSource
    let useWebExtras: Bool
}

struct ClaudeProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .claude
    let style: IconStyle = .claude

    @MainActor
    func settingsToggles(context: ProviderSettingsContext) -> [ProviderSettingsToggleDescriptor] {
        let l10n = context.localization
        let id = "claude.webExtras"

        let statusText: () -> String? = { context.statusText(id) }

        let toggle = ProviderSettingsToggleDescriptor(
            id: id,
            title: l10n.choose("Augment Claude via web", "Web経由でClaudeを補完"),
            subtitle: l10n.choose(
                [
                    "Uses Safari/Chrome/Firefox session cookies to add extra dashboard fields on top of OAuth.",
                    "Adds Extra usage spend/limit.",
                    "Safari → Chrome → Firefox.",
                ].joined(separator: " "),
                [
                    "Safari/Chrome/Firefoxのセッションクッキーを使い、OAuthに追加のダッシュボード項目を加えます。",
                    "追加使用量の利用額/上限を表示します。",
                    "Safari → Chrome → Firefox。",
                ].joined(separator: " ")),
            binding: context.boolBinding(\.claudeWebExtrasEnabled),
            statusText: statusText,
            actions: [],
            isVisible: { context.settings.claudeUsageDataSource == .cli },
            onChange: { enabled in
                if !enabled {
                    context.setStatusText(id, nil)
                }
            },
            onAppDidBecomeActive: nil,
            onAppearWhenEnabled: {
                await Self.refreshWebExtrasStatus(context: context, id: id)
            })

        return [toggle]
    }

    @MainActor
    static func usageStrategy(
        settings: SettingsStore,
        hasWebSession: () -> Bool = { ClaudeWebAPIFetcher.hasSessionKey() }) -> ClaudeUsageStrategy
    {
        if settings.debugMenuEnabled {
            let dataSource = settings.claudeUsageDataSource
            if dataSource == .oauth {
                return ClaudeUsageStrategy(dataSource: dataSource, useWebExtras: false)
            }
            let hasSession = hasWebSession()
            if dataSource == .web, !hasSession {
                return ClaudeUsageStrategy(dataSource: .cli, useWebExtras: false)
            }
            let useWebExtras = dataSource == .cli && settings.claudeWebExtrasEnabled && hasSession
            return ClaudeUsageStrategy(dataSource: dataSource, useWebExtras: useWebExtras)
        }

        let hasSession = hasWebSession()
        let dataSource: ClaudeUsageDataSource = hasSession ? .web : .cli
        return ClaudeUsageStrategy(dataSource: dataSource, useWebExtras: false)
    }

    func makeFetch(context: ProviderBuildContext) -> @Sendable () async throws -> UsageSnapshot {
        {
            let strategy = await MainActor.run { Self.usageStrategy(settings: context.settings) }

            let fetcher: any ClaudeUsageFetching = if context.claudeFetcher is ClaudeUsageFetcher {
                ClaudeUsageFetcher(dataSource: strategy.dataSource, useWebExtras: strategy.useWebExtras)
            } else {
                context.claudeFetcher
            }

            let usage = try await fetcher.loadLatestUsage(model: "sonnet")
            return UsageSnapshot(
                primary: usage.primary,
                secondary: usage.secondary,
                tertiary: usage.opus,
                providerCost: usage.providerCost,
                updatedAt: usage.updatedAt,
                accountEmail: usage.accountEmail,
                accountOrganization: usage.accountOrganization,
                loginMethod: usage.loginMethod)
        }
    }

    // MARK: - Web extras status

    @MainActor
    private static func refreshWebExtrasStatus(context: ProviderSettingsContext, id: String) async {
        let expectedEmail = context.store.snapshot(for: .claude)?.accountEmail?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let l10n = context.localization
        context.setStatusText(id, l10n.choose("Checking Claude cookies…", "ClaudeのCookieを確認中…"))
        let status = await Self.loadClaudeWebStatus(expectedEmail: expectedEmail, language: context.language)
        context.setStatusText(id, status)
    }

    private static func loadClaudeWebStatus(expectedEmail: String?, language: AppLanguage) async -> String {
        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        return await Task.detached(priority: .utility) {
            do {
                let info = try ClaudeWebAPIFetcher.sessionKeyInfo()
                var parts = [
                    l10n.choose(
                        "Using \(info.sourceLabel) cookies (\(info.cookieCount)).",
                        "\(info.sourceLabel) のCookieを使用（\(info.cookieCount)件）。"),
                ]

                do {
                    let usage = try await ClaudeWebAPIFetcher.fetchUsage(using: info)
                    if let rawEmail = usage.accountEmail?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !rawEmail.isEmpty
                    {
                        if let expectedEmail, !expectedEmail.isEmpty {
                            let matches = rawEmail.lowercased() == expectedEmail.lowercased()
                            let matchText = matches
                                ? l10n.choose("matches Claude", "Claudeと一致")
                                : l10n.choose("does not match Claude", "Claudeと不一致")
                            parts.append(l10n.choose(
                                "Signed in as \(rawEmail) (\(matchText)).",
                                "ログイン中: \(rawEmail)（\(matchText)）。"))
                        } else {
                            parts.append(l10n.choose("Signed in as \(rawEmail).", "ログイン中: \(rawEmail)。"))
                        }
                    }
                } catch {
                    let errorText = external.localizedErrorMessage(error.localizedDescription)
                    parts.append(l10n.choose(
                        "Signed-in status unavailable: \(errorText)",
                        "ログイン状況を取得できません: \(errorText)"))
                }

                return parts.joined(separator: " ")
            } catch {
                let errorText = external.localizedErrorMessage(error.localizedDescription)
                return l10n.choose(
                    "Browser cookie import failed: \(errorText)",
                    "ブラウザCookieの読み込みに失敗: \(errorText)")
            }
        }.value
    }
}
