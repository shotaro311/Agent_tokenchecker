import AppKit
import CodexBarCore
import SwiftUI

@MainActor
struct DebugPane: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore
    @State private var currentLogProvider: UsageProvider = .codex
    @State private var isLoadingLog = false
    @State private var logText: String = ""
    @State private var isClearingCostCache = false
    @State private var costCacheStatus: String?
    #if DEBUG
    @State private var currentErrorProvider: UsageProvider = .codex
    @State private var simulatedErrorText: String = ""
    #endif
    private var l10n: AppLocalization { AppLocalization(language: self.settings.appLanguage) }
    private var external: ExternalTextLocalizer { ExternalTextLocalizer(language: self.settings.appLanguage) }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection {
                    PreferenceToggleRow(
                        title: self.l10n.choose("Force animation on next refresh", "次の更新でアニメーションを強制"),
                        subtitle: self.l10n.choose(
                            "Temporarily shows the loading animation after the next refresh.",
                            "次回の更新後に一時的に読み込みアニメーションを表示します。"),
                        binding: self.$store.debugForceAnimation)
                }

                SettingsSection(
                    title: self.l10n.choose("Loading animations", "読み込みアニメーション"),
                    caption: self.l10n.choose(
                        "Pick a pattern and replay it in the menu bar. \"Random\" keeps the existing behavior.",
                        "パターンを選んでメニューバーで再生します。「ランダム」は既存の挙動を維持します。"))
                {
                    Picker(self.l10n.choose("Animation pattern", "アニメーションパターン"), selection: self.animationPatternBinding) {
                        Text(self.l10n.choose("Random (default)", "ランダム（既定）")).tag(nil as LoadingPattern?)
                        ForEach(LoadingPattern.allCases) { pattern in
                            Text(pattern.displayName).tag(Optional(pattern))
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Button(self.l10n.choose("Replay selected animation", "選択したアニメーションを再生")) {
                        self.replaySelectedAnimation()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button {
                        NotificationCenter.default.post(name: .codexbarDebugBlinkNow, object: nil)
                    } label: {
                        Label(self.l10n.choose("Blink now", "今すぐ点滅"), systemImage: "eyes")
                    }
                    .controlSize(.small)
                }

                SettingsSection(
                    title: self.l10n.choose("Claude data source", "Claudeデータソース"),
                    caption: self.l10n.choose("Debug override for Claude usage fetching.", "Claude使用量取得のデバッグ用上書き。"))
                {
                    Picker(self.l10n.choose("Source", "ソース"), selection: self.$settings.claudeUsageDataSource) {
                        ForEach(ClaudeUsageDataSource.allCases) { source in
                            Text(source.displayName(language: self.settings.appLanguage)).tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 240)
                }

                SettingsSection(
                    title: self.l10n.choose("Probe logs", "プローブログ"),
                    caption: self.l10n.choose(
                        "Fetch the latest PTY scrape for Codex or Claude; Copy keeps the full text.",
                        "Codex/Claudeの最新PTYログを取得します。コピーは全文を保持します。"))
                {
                    Picker(self.l10n.choose("Provider", "プロバイダ"), selection: self.$currentLogProvider) {
                        Text(self.external.providerShortName(.codex)).tag(UsageProvider.codex)
                        Text(self.external.providerShortName(.claude)).tag(UsageProvider.claude)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)

                    HStack(spacing: 12) {
                        Button { self.loadLog(self.currentLogProvider) } label: {
                            Label(self.l10n.choose("Fetch log", "ログを取得"), systemImage: "arrow.clockwise")
                        }
                        .disabled(self.isLoadingLog)

                        Button { self.copyToPasteboard(self.logText) } label: {
                            Label(self.l10n.choose("Copy", "コピー"), systemImage: "doc.on.doc")
                        }
                        .disabled(self.logText.isEmpty)

                        Button { self.saveLog(self.currentLogProvider) } label: {
                            Label(self.l10n.choose("Save to file", "ファイルに保存"), systemImage: "externaldrive.badge.plus")
                        }
                        .disabled(self.isLoadingLog && self.logText.isEmpty)

                        if self.currentLogProvider == .claude {
                            Button { self.loadClaudeDump() } label: {
                                Label(self.l10n.choose("Load parse dump", "解析ダンプを読み込み"), systemImage: "doc.text.magnifyingglass")
                            }
                            .disabled(self.isLoadingLog)
                        }
                    }

                    Button {
                        self.settings.rerunProviderDetection()
                        self.loadLog(self.currentLogProvider)
                    } label: {
                        Label(
                            self.l10n.choose("Re-run provider autodetect", "プロバイダ自動検出を再実行"),
                            systemImage: "dot.radiowaves.left.and.right")
                    }
                    .controlSize(.small)

                    ZStack(alignment: .topLeading) {
                        ScrollView {
                            Text(self.displayedLog)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(minHeight: 160, maxHeight: 220)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)

                        if self.isLoadingLog {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                }

                SettingsSection(
                    title: self.l10n.choose("OpenAI web access", "OpenAI Webアクセス"),
                    caption: self.l10n.choose(
                        "Cookie import + WebKit scrape logs from the last “Access OpenAI via web” attempt.",
                        "直近の「WebでOpenAIにアクセス」実行におけるCookie取り込みとWebKitスクレイプのログ。"))
                {
                    HStack(spacing: 12) {
                        Button { self.copyToPasteboard(self.store.openAIDashboardCookieImportDebugLog ?? "") } label: {
                            Label(self.l10n.choose("Copy", "コピー"), systemImage: "doc.on.doc")
                        }
                        .disabled((self.store.openAIDashboardCookieImportDebugLog ?? "").isEmpty)
                    }

                    ScrollView {
                        Text(self.store.openAIDashboardCookieImportDebugLog?.isEmpty == false
                            ? (self.store.openAIDashboardCookieImportDebugLog ?? "")
                            : self.l10n.choose(
                                "No log yet. Enable “Access OpenAI via web” in General to run an import.",
                                "ログがまだありません。一般で「WebでOpenAIにアクセス」を有効にして取り込みを実行してください。"))
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(minHeight: 120, maxHeight: 180)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                }

                SettingsSection(
                    title: self.l10n.choose("Caches", "キャッシュ"),
                    caption: self.l10n.choose("Clear cached cost scan results.", "コストスキャン結果のキャッシュを削除します。"))
                {
                    let isTokenRefreshActive = self.store.isTokenRefreshInFlight(for: .codex)
                        || self.store.isTokenRefreshInFlight(for: .claude)

                    HStack(spacing: 12) {
                        Button {
                            Task { await self.clearCostCache() }
                        } label: {
                            Label(self.l10n.choose("Clear cost cache", "コストキャッシュを削除"), systemImage: "trash")
                        }
                        .disabled(self.isClearingCostCache || isTokenRefreshActive)

                        if let status = self.costCacheStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                SettingsSection(
                    title: self.l10n.choose("Notifications", "通知"),
                    caption: self.l10n.choose(
                        "Trigger test notifications for the 5-hour session window (depleted/restored).",
                        "5時間セッション枠のテスト通知（枯渇/復旧）を送信します。"))
                {
                    Picker(self.l10n.choose("Provider", "プロバイダ"), selection: self.$currentLogProvider) {
                        Text(self.external.providerShortName(.codex)).tag(UsageProvider.codex)
                        Text(self.external.providerShortName(.claude)).tag(UsageProvider.claude)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)

                    HStack(spacing: 12) {
                        Button {
                            self.postSessionNotification(.depleted, provider: self.currentLogProvider)
                        } label: {
                            Label(self.l10n.choose("Post depleted", "枯渇を通知"), systemImage: "bell.badge")
                        }
                        .controlSize(.small)

                        Button {
                            self.postSessionNotification(.restored, provider: self.currentLogProvider)
                        } label: {
                            Label(self.l10n.choose("Post restored", "復旧を通知"), systemImage: "bell")
                        }
                        .controlSize(.small)
                    }
                }

                #if DEBUG
                SettingsSection(
                    title: self.l10n.choose("Error simulation", "エラーシミュレーション"),
                    caption: self.l10n.choose(
                        "Inject a fake error message into the menu card for layout testing.",
                        "メニューカードにテスト用エラーを挿入してレイアウトを確認します。"))
                {
                    Picker(self.l10n.choose("Provider", "プロバイダ"), selection: self.$currentErrorProvider) {
                        Text(self.external.providerShortName(.codex)).tag(UsageProvider.codex)
                        Text(self.external.providerShortName(.claude)).tag(UsageProvider.claude)
                        Text(self.external.providerShortName(.gemini)).tag(UsageProvider.gemini)
                        Text(self.external.providerShortName(.antigravity)).tag(UsageProvider.antigravity)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)

                    TextField(
                        self.l10n.choose("Simulated error text", "テスト用エラー文"),
                        text: self.$simulatedErrorText,
                        axis: .vertical)
                        .lineLimit(4)
                        .onAppear {
                            if self.simulatedErrorText.isEmpty {
                                self.simulatedErrorText = self.defaultSimulatedErrorText
                            }
                        }

                    HStack(spacing: 12) {
                        Button {
                            self.store._setErrorForTesting(
                                self.simulatedErrorText,
                                provider: self.currentErrorProvider)
                        } label: {
                            Label(self.l10n.choose("Set menu error", "メニューエラーを設定"), systemImage: "exclamationmark.triangle")
                        }
                        .controlSize(.small)

                        Button {
                            self.store._setErrorForTesting(nil, provider: self.currentErrorProvider)
                        } label: {
                            Label(self.l10n.choose("Clear menu error", "メニューエラーを解除"), systemImage: "xmark.circle")
                        }
                        .controlSize(.small)
                    }

                    let supportsTokenError = self.currentErrorProvider == .codex || self.currentErrorProvider == .claude
                    HStack(spacing: 12) {
                        Button {
                            self.store._setTokenErrorForTesting(
                                self.simulatedErrorText,
                                provider: self.currentErrorProvider)
                        } label: {
                            Label(self.l10n.choose("Set cost error", "コストエラーを設定"), systemImage: "banknote")
                        }
                        .controlSize(.small)
                        .disabled(!supportsTokenError)

                        Button {
                            self.store._setTokenErrorForTesting(nil, provider: self.currentErrorProvider)
                        } label: {
                            Label(self.l10n.choose("Clear cost error", "コストエラーを解除"), systemImage: "xmark.circle")
                        }
                        .controlSize(.small)
                        .disabled(!supportsTokenError)
                    }
                }
                #endif

                SettingsSection(
                    title: self.l10n.choose("CLI paths", "CLIパス"),
                    caption: self.l10n.choose(
                        "Resolved Codex binary and PATH layers; startup login PATH capture (short timeout).",
                        "CodexバイナリとPATHの解決結果、起動時ログインPATHの短時間キャプチャを表示します。"))
                {
                    self.binaryRow(
                        title: self.l10n.choose("Codex binary", "Codexバイナリ"),
                        value: self.store.pathDebugInfo.codexBinary)
                    self.binaryRow(
                        title: self.l10n.choose("Claude binary", "Claudeバイナリ"),
                        value: self.store.pathDebugInfo.claudeBinary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(self.l10n.choose("Effective PATH", "有効なPATH"))
                            .font(.callout.weight(.semibold))
                        ScrollView {
                            Text(self.store.pathDebugInfo.effectivePATH.isEmpty
                                ? self.l10n.choose("Unavailable", "利用不可")
                                : self.store.pathDebugInfo.effectivePATH)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                        }
                        .frame(minHeight: 60, maxHeight: 110)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    }

                    if let loginPATH = self.store.pathDebugInfo.loginShellPATH {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(self.l10n.choose("Login shell PATH (startup capture)", "ログインシェルのPATH（起動時キャプチャ）"))
                                .font(.callout.weight(.semibold))
                            ScrollView {
                                Text(loginPATH)
                                    .font(.system(.footnote, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(6)
                            }
                            .frame(minHeight: 60, maxHeight: 110)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var animationPatternBinding: Binding<LoadingPattern?> {
        Binding(
            get: { self.settings.debugLoadingPattern },
            set: { self.settings.debugLoadingPattern = $0 })
    }

    private func replaySelectedAnimation() {
        var userInfo: [AnyHashable: Any] = [:]
        if let pattern = self.settings.debugLoadingPattern {
            userInfo["pattern"] = pattern.rawValue
        }
        NotificationCenter.default.post(
            name: .codexbarDebugReplayAllAnimations,
            object: nil,
            userInfo: userInfo.isEmpty ? nil : userInfo)
        self.store.replayLoadingAnimation(duration: 4)
    }

    private var displayedLog: String {
        if self.logText.isEmpty {
            return self.isLoadingLog
                ? self.l10n.choose("Loading…", "読み込み中…")
                : self.l10n.choose("No log yet. Fetch to load.", "ログがまだありません。取得してください。")
        }
        return self.logText
    }

    private var defaultSimulatedErrorText: String {
        self.l10n.choose(
            """
            Simulated error for testing layout.
            Second line.
            Third line.
            Fourth line.
            """,
            """
            レイアウト確認用のテストエラーです。
            2行目。
            3行目。
            4行目。
            """)
    }

    private func loadLog(_ provider: UsageProvider) {
        self.isLoadingLog = true
        Task {
            let text = await self.store.debugLog(for: provider)
            await MainActor.run {
                self.logText = text
                self.isLoadingLog = false
            }
        }
    }

    private func saveLog(_ provider: UsageProvider) {
        Task {
            if self.logText.isEmpty {
                self.isLoadingLog = true
                let text = await self.store.debugLog(for: provider)
                await MainActor.run { self.logText = text }
                self.isLoadingLog = false
            }
            _ = await self.store.dumpLog(toFileFor: provider)
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func binaryRow(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout.weight(.semibold))
            Text(value ?? self.l10n.choose("Not found", "見つかりません"))
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
    }

    private func loadClaudeDump() {
        self.isLoadingLog = true
        Task {
            let text = await self.store.debugClaudeDump()
            await MainActor.run {
                self.logText = text
                self.isLoadingLog = false
            }
        }
    }

    private func postSessionNotification(_ transition: SessionQuotaTransition, provider: UsageProvider) {
        SessionQuotaNotifier().post(transition: transition, provider: provider, badge: 1)
    }

    private func clearCostCache() async {
        guard !self.isClearingCostCache else { return }
        self.isClearingCostCache = true
        self.costCacheStatus = nil
        defer { self.isClearingCostCache = false }

        if let error = await self.store.clearCostUsageCache() {
            self.costCacheStatus = self.l10n.choose("Failed: \(error)", "失敗: \(error)")
            return
        }

        self.costCacheStatus = self.l10n.choose("Cleared.", "削除しました。")
    }
}
