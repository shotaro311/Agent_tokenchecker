import CodexBarCore
import Foundation

struct CodexProviderImplementation: ProviderImplementation {
    let id: UsageProvider
    let style: IconStyle = .codex

    init(id: UsageProvider = .codex) {
        self.id = id
    }

    func makeFetch(context: ProviderBuildContext) -> @Sendable () async throws -> UsageSnapshot {
        {
            let env = await MainActor.run {
                context.settings.codexEnvironment(for: self.id)
            }
            let fetcher = UsageFetcher(environment: env)
            return try await fetcher.loadLatestUsage()
        }
    }

    @MainActor
    func settingsToggles(context: ProviderSettingsContext) -> [ProviderSettingsToggleDescriptor] {
        []
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        let l10n = context.localization
        let provider = context.provider

        let displayNameKeyPath: ReferenceWritableKeyPath<SettingsStore, String>
        let homePathKeyPath: ReferenceWritableKeyPath<SettingsStore, String>
        let defaultDisplayName: String
        let defaultHomePath: String

        switch provider {
        case .codex:
            displayNameKeyPath = \.codexDisplayName
            homePathKeyPath = \.codexHomePath
            defaultDisplayName = "Codex"
            defaultHomePath = "~/.codex"
        case .codexOwner:
            displayNameKeyPath = \.codexOwnerDisplayName
            homePathKeyPath = \.codexOwnerHomePath
            defaultDisplayName = "Codex (Owner)"
            defaultHomePath = "~/.codex-owner"
        case .codexMember:
            displayNameKeyPath = \.codexMemberDisplayName
            homePathKeyPath = \.codexMemberHomePath
            defaultDisplayName = "Codex (Member)"
            defaultHomePath = "~/.codex-member"
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            return []
        }

        let displayNameField = ProviderSettingsFieldDescriptor(
            id: "codex-display-name-\(provider.rawValue)",
            title: l10n.choose("Display name", "表示名"),
            subtitle: l10n.choose(
                "Shown in menus and settings for this Codex account.",
                "このCodexアカウントのメニュー/設定で表示されます。"),
            kind: .plain,
            placeholder: defaultDisplayName,
            binding: context.stringBinding(displayNameKeyPath),
            actions: [
                ProviderSettingsActionDescriptor(
                    id: "codex-display-name-reset-\(provider.rawValue)",
                    title: l10n.choose("Reset", "リセット"),
                    style: .bordered,
                    isVisible: nil,
                    perform: { [weak settings = context.settings] in
                        settings?.resetCodexDisplayName(for: provider)
                    }),
            ],
            isVisible: nil)

        let homeField = ProviderSettingsFieldDescriptor(
            id: "codex-home-\(provider.rawValue)",
            title: l10n.choose("Codex home (CODEX_HOME)", "紐付けパス（CODEX_HOME）"),
            subtitle: l10n.choose(
                "Directory that contains auth.json and sessions for this account (supports ~).",
                "このアカウントの auth.json / sessions を含むディレクトリです（~対応）。"),
            kind: .plain,
            placeholder: defaultHomePath,
            binding: context.stringBinding(homePathKeyPath),
            actions: [
                ProviderSettingsActionDescriptor(
                    id: "codex-home-reset-\(provider.rawValue)",
                    title: l10n.choose("Reset", "リセット"),
                    style: .bordered,
                    isVisible: nil,
                    perform: { [weak settings = context.settings] in
                        settings?.resetCodexHomePath(for: provider)
                    }),
                ProviderSettingsActionDescriptor(
                    id: "codex-home-refresh-\(provider.rawValue)",
                    title: l10n.choose("Refresh now", "今すぐ更新"),
                    style: .bordered,
                    isVisible: nil,
                    perform: { [weak store = context.store] in
                        await store?.refresh()
                    }),
            ],
            isVisible: nil)

        return [displayNameField, homeField]
    }
}
