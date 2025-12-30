import AppKit
import CodexBarCore
import SwiftUI

@MainActor
struct GeneralPane: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore

    var body: some View {
        let l10n = AppLocalization(language: self.settings.appLanguage)
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("Language", "言語"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Picker("", selection: self.$settings.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(l10n.choose("Switch the app language.", "アプリの表示言語を切り替えます。"))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("System", "システム"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: l10n.choose("Start at Login", "ログイン時に起動"),
                        subtitle: l10n.choose(
                            "Automatically opens CodexBar when you start your Mac.",
                            "Macの起動時にCodexBarを自動で開きます。"),
                        binding: self.$settings.launchAtLogin)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("Usage", "使用量"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: 5.4) {
                        Toggle(isOn: self.$settings.ccusageCostUsageEnabled) {
                            Text(l10n.choose("Show cost summary", "コスト集計を表示"))
                                .font(.body)
                        }
                        .toggleStyle(.checkbox)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.choose(
                                "Reads local usage logs. Shows today + last 30 days cost in the menu.",
                                "ローカルの使用量ログを読み、今日と直近30日分のコストをメニューに表示します。"))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)

                            if self.settings.ccusageCostUsageEnabled {
                                Text(l10n.choose(
                                    "Auto-refresh: hourly · Timeout: 10m",
                                    "自動更新: 1時間ごと · タイムアウト: 10分"))
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)

                                self.costStatusLine(provider: .claude)
                                self.costStatusLine(provider: .codex)
                            }
                        }
                    }
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("Status", "ステータス"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: l10n.choose("Check provider status", "プロバイダのステータスを確認"),
                        subtitle: l10n.choose(
                            "Polls OpenAI/Claude status pages and Google Workspace for " +
                                "Gemini/Antigravity, surfacing incidents in the icon and menu.",
                            "OpenAI/ClaudeのステータスページとGoogle Workspaceを監視し、" +
                                "Gemini/Antigravityの障害をアイコンとメニューに表示します。"),
                        binding: self.$settings.statusChecksEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("Notifications", "通知"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: l10n.choose("Session quota notifications", "セッション上限の通知"),
                        subtitle: l10n.choose(
                            "Notifies when the 5-hour session quota hits 0% and when it becomes " +
                                "available again.",
                            "5時間セッションの上限が0%になった時と、再び利用可能になった時に通知します。"),
                        binding: self.$settings.sessionQuotaNotificationsEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    HStack {
                        Spacer()
                        Button(l10n.choose("Quit CodexBar", "CodexBarを終了")) { NSApp.terminate(nil) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func costStatusLine(provider: UsageProvider) -> some View {
        let l10n = AppLocalization(language: self.settings.appLanguage)
        let external = ExternalTextLocalizer(language: self.settings.appLanguage)
        let name = switch provider {
        case .claude:
            external.providerName(.claude)
        case .codex:
            external.providerName(.codex)
        case .zai:
            external.providerName(.zai)
        case .gemini:
            external.providerName(.gemini)
        case .antigravity:
            external.providerName(.antigravity)
        case .cursor:
            external.providerName(.cursor)
        case .factory:
            external.providerName(.factory)
        }
        guard provider == .claude || provider == .codex else {
            return Text(l10n.choose("\(name): unsupported", "\(name): 未対応"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }

        if self.store.isTokenRefreshInFlight(for: provider) {
            let elapsed: String = {
                guard let startedAt = self.store.tokenLastAttemptAt(for: provider) else { return "" }
                let seconds = max(0, Date().timeIntervalSince(startedAt))
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = seconds < 60 ? [.second] : [.minute, .second]
                formatter.unitsStyle = .abbreviated
                var calendar = Calendar.current
                calendar.locale = l10n.locale
                formatter.calendar = calendar
                return formatter.string(from: seconds).map { " (\($0))" } ?? ""
            }()
            return Text(l10n.choose("\(name): fetching…\(elapsed)", "\(name): 取得中…\(elapsed)"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        if let snapshot = self.store.tokenSnapshot(for: provider) {
            let updated = UsageFormatter.updatedString(from: snapshot.updatedAt, language: self.settings.appLanguage)
            let cost = snapshot.last30DaysCostUSD.map {
                UsageFormatter.usdString($0, language: self.settings.appLanguage)
            } ?? "—"
            return Text(l10n.choose(
                "\(name): \(updated) · 30d \(cost)",
                "\(name): \(updated) · 30日 \(cost)"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        if let error = self.store.tokenError(for: provider), !error.isEmpty {
            let localizedError = external.localizedErrorMessage(error)
            let truncated = UsageFormatter.truncatedSingleLine(localizedError, max: 120)
            return Text("\(name): \(truncated)")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        if let lastAttempt = self.store.tokenLastAttemptAt(for: provider) {
            let rel = RelativeDateTimeFormatter()
            rel.unitsStyle = .abbreviated
            rel.locale = l10n.locale
            let when = rel.localizedString(for: lastAttempt, relativeTo: Date())
            return Text(l10n.choose("\(name): last attempt \(when)", "\(name): 最終試行 \(when)"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        return Text(l10n.choose("\(name): no data yet", "\(name): まだデータがありません"))
            .font(.footnote)
            .foregroundStyle(.tertiary)
    }
}
