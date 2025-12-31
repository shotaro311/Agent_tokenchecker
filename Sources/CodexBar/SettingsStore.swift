import AppKit
import CodexBarCore
import Observation
import ServiceManagement

enum RefreshFrequency: String, CaseIterable, Identifiable {
    case manual
    case oneMinute
    case twoMinutes
    case fiveMinutes
    case fifteenMinutes

    var id: String { self.rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .manual: nil
        case .oneMinute: 60
        case .twoMinutes: 120
        case .fiveMinutes: 300
        case .fifteenMinutes: 900
        }
    }

    func label(language: AppLanguage) -> String {
        switch self {
        case .manual:
            language == .japanese ? "手動" : "Manual"
        case .oneMinute:
            language == .japanese ? "1分" : "1 min"
        case .twoMinutes:
            language == .japanese ? "2分" : "2 min"
        case .fiveMinutes:
            language == .japanese ? "5分" : "5 min"
        case .fifteenMinutes:
            language == .japanese ? "15分" : "15 min"
        }
    }
}

@MainActor
@Observable
final class SettingsStore {
    /// Persisted provider display order.
    ///
    /// Stored as raw `UsageProvider` strings so new providers can be appended automatically without breaking.
    private var providerOrderRaw: [String] {
        didSet { self.userDefaults.set(self.providerOrderRaw, forKey: "providerOrder") }
    }

    var refreshFrequency: RefreshFrequency {
        didSet { self.userDefaults.set(self.refreshFrequency.rawValue, forKey: "refreshFrequency") }
    }

    var appLanguage: AppLanguage {
        didSet {
            self.userDefaults.set(self.appLanguage.rawValue, forKey: "appLanguage")
            if self.syncAppLanguageToSharedStore {
                AppLanguageStore.save(self.appLanguage)
            }
        }
    }

    var launchAtLogin: Bool {
        didSet {
            self.userDefaults.set(self.launchAtLogin, forKey: "launchAtLogin")
            LaunchAtLoginManager.setEnabled(self.launchAtLogin)
        }
    }

    /// Hidden toggle to reveal debug-only menu items (enable via defaults write com.steipete.CodexBar debugMenuEnabled
    /// -bool YES).
    var debugMenuEnabled: Bool {
        didSet { self.userDefaults.set(self.debugMenuEnabled, forKey: "debugMenuEnabled") }
    }

    private var debugLoadingPatternRaw: String? {
        didSet {
            if let raw = self.debugLoadingPatternRaw {
                self.userDefaults.set(raw, forKey: "debugLoadingPattern")
            } else {
                self.userDefaults.removeObject(forKey: "debugLoadingPattern")
            }
        }
    }

    var statusChecksEnabled: Bool {
        didSet { self.userDefaults.set(self.statusChecksEnabled, forKey: "statusChecksEnabled") }
    }

    var sessionQuotaNotificationsEnabled: Bool {
        didSet {
            self.userDefaults.set(self.sessionQuotaNotificationsEnabled, forKey: "sessionQuotaNotificationsEnabled")
        }
    }

    /// When enabled, progress bars show "percent used" instead of "percent left".
    var usageBarsShowUsed: Bool {
        didSet { self.userDefaults.set(self.usageBarsShowUsed, forKey: "usageBarsShowUsed") }
    }

    /// Optional: show provider cost summary from local usage logs (Codex + Claude).
    var ccusageCostUsageEnabled: Bool {
        didSet { self.userDefaults.set(self.ccusageCostUsageEnabled, forKey: "tokenCostUsageEnabled") }
    }

    var randomBlinkEnabled: Bool {
        didSet { self.userDefaults.set(self.randomBlinkEnabled, forKey: "randomBlinkEnabled") }
    }

    // MARK: - Codex multi-account (display name + CODEX_HOME)

    var codexDisplayName: String {
        didSet { self.userDefaults.set(self.codexDisplayName, forKey: "codexDisplayName") }
    }

    var codexHomePath: String {
        didSet { self.userDefaults.set(self.codexHomePath, forKey: "codexHomePath") }
    }

    var codexOwnerDisplayName: String {
        didSet { self.userDefaults.set(self.codexOwnerDisplayName, forKey: "codexOwnerDisplayName") }
    }

    var codexOwnerHomePath: String {
        didSet { self.userDefaults.set(self.codexOwnerHomePath, forKey: "codexOwnerHomePath") }
    }

    var codexMemberDisplayName: String {
        didSet { self.userDefaults.set(self.codexMemberDisplayName, forKey: "codexMemberDisplayName") }
    }

    var codexMemberHomePath: String {
        didSet { self.userDefaults.set(self.codexMemberHomePath, forKey: "codexMemberHomePath") }
    }

    /// Optional: augment Claude usage with claude.ai web API (via Safari/Chrome/Firefox cookies),
    /// incl. "Extra usage" spend.
    var claudeWebExtrasEnabled: Bool {
        didSet { self.userDefaults.set(self.claudeWebExtrasEnabled, forKey: "claudeWebExtrasEnabled") }
    }

    /// Optional: show Codex credits + Claude extra usage sections in the menu UI.
    var showOptionalCreditsAndExtraUsage: Bool {
        didSet {
            self.userDefaults.set(self.showOptionalCreditsAndExtraUsage, forKey: "showOptionalCreditsAndExtraUsage")
        }
    }

    private var claudeUsageDataSourceRaw: String? {
        didSet {
            if let raw = self.claudeUsageDataSourceRaw {
                self.userDefaults.set(raw, forKey: "claudeUsageDataSource")
            } else {
                self.userDefaults.removeObject(forKey: "claudeUsageDataSource")
            }
        }
    }

    /// Optional: collapse provider icons into a single menu bar item with an in-menu switcher.
    var mergeIcons: Bool {
        didSet { self.userDefaults.set(self.mergeIcons, forKey: "mergeIcons") }
    }

    /// Optional: show provider icons in the in-menu switcher.
    var switcherShowsIcons: Bool {
        didSet { self.userDefaults.set(self.switcherShowsIcons, forKey: "switcherShowsIcons") }
    }

    /// z.ai API token (stored in Keychain).
    var zaiAPIToken: String {
        didSet { self.schedulePersistZaiAPIToken() }
    }

    private var selectedMenuProviderRaw: String? {
        didSet {
            if let raw = self.selectedMenuProviderRaw {
                self.userDefaults.set(raw, forKey: "selectedMenuProvider")
            } else {
                self.userDefaults.removeObject(forKey: "selectedMenuProvider")
            }
        }
    }

    /// Optional override for the loading animation pattern, exposed via the Debug tab.
    var debugLoadingPattern: LoadingPattern? {
        get { self.debugLoadingPatternRaw.flatMap(LoadingPattern.init(rawValue:)) }
        set {
            self.debugLoadingPatternRaw = newValue?.rawValue
        }
    }

    var selectedMenuProvider: UsageProvider? {
        get { self.selectedMenuProviderRaw.flatMap(UsageProvider.init(rawValue:)) }
        set {
            self.selectedMenuProviderRaw = newValue?.rawValue
        }
    }

    var claudeUsageDataSource: ClaudeUsageDataSource {
        get { ClaudeUsageDataSource(rawValue: self.claudeUsageDataSourceRaw ?? "") ?? .web }
        set {
            self.claudeUsageDataSourceRaw = newValue.rawValue
            if newValue != .cli {
                self.claudeWebExtrasEnabled = false
            }
        }
    }

    var menuObservationToken: Int {
        _ = self.providerOrderRaw
        _ = self.refreshFrequency
        _ = self.appLanguage
        _ = self.launchAtLogin
        _ = self.debugMenuEnabled
        _ = self.statusChecksEnabled
        _ = self.sessionQuotaNotificationsEnabled
        _ = self.usageBarsShowUsed
        _ = self.ccusageCostUsageEnabled
        _ = self.randomBlinkEnabled
        _ = self.codexDisplayName
        _ = self.codexHomePath
        _ = self.codexOwnerDisplayName
        _ = self.codexOwnerHomePath
        _ = self.codexMemberDisplayName
        _ = self.codexMemberHomePath
        _ = self.claudeWebExtrasEnabled
        _ = self.showOptionalCreditsAndExtraUsage
        _ = self.claudeUsageDataSource
        _ = self.mergeIcons
        _ = self.switcherShowsIcons
        _ = self.zaiAPIToken
        _ = self.debugLoadingPattern
        _ = self.selectedMenuProvider
        _ = self.providerToggleRevision
        return 0
    }

    private var providerDetectionCompleted: Bool {
        didSet { self.userDefaults.set(self.providerDetectionCompleted, forKey: "providerDetectionCompleted") }
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let syncAppLanguageToSharedStore: Bool
    @ObservationIgnored private let toggleStore: ProviderToggleStore
    @ObservationIgnored private let zaiTokenStore: any ZaiTokenStoring
    @ObservationIgnored private var zaiTokenPersistTask: Task<Void, Never>?
    private var providerToggleRevision: Int = 0

    init(
        userDefaults: UserDefaults = .standard,
        zaiTokenStore: any ZaiTokenStoring = KeychainZaiTokenStore(),
        syncAppLanguageToSharedStore: Bool = true)
    {
        self.userDefaults = userDefaults
        self.zaiTokenStore = zaiTokenStore
        self.syncAppLanguageToSharedStore = syncAppLanguageToSharedStore
        self.providerOrderRaw = userDefaults.stringArray(forKey: "providerOrder") ?? []
        let raw = userDefaults.string(forKey: "refreshFrequency") ?? RefreshFrequency.fiveMinutes.rawValue
        self.refreshFrequency = RefreshFrequency(rawValue: raw) ?? .fiveMinutes
        let languageRaw = userDefaults.string(forKey: "appLanguage")
        let resolvedLanguage = AppLanguage(rawValue: languageRaw ?? "") ?? .japanese
        self.appLanguage = resolvedLanguage
        if languageRaw == nil {
            self.userDefaults.set(resolvedLanguage.rawValue, forKey: "appLanguage")
        }
        if self.syncAppLanguageToSharedStore {
            AppLanguageStore.save(resolvedLanguage)
        }
        self.launchAtLogin = userDefaults.object(forKey: "launchAtLogin") as? Bool ?? false
        self.debugMenuEnabled = userDefaults.object(forKey: "debugMenuEnabled") as? Bool ?? false
        self.debugLoadingPatternRaw = userDefaults.string(forKey: "debugLoadingPattern")
        self.statusChecksEnabled = userDefaults.object(forKey: "statusChecksEnabled") as? Bool ?? true
        let sessionQuotaNotificationsDefault = userDefaults.object(
            forKey: "sessionQuotaNotificationsEnabled") as? Bool
        self.sessionQuotaNotificationsEnabled = sessionQuotaNotificationsDefault ?? true
        if sessionQuotaNotificationsDefault == nil {
            self.userDefaults.set(true, forKey: "sessionQuotaNotificationsEnabled")
        }
        self.usageBarsShowUsed = userDefaults.object(forKey: "usageBarsShowUsed") as? Bool ?? false
        self.ccusageCostUsageEnabled = userDefaults.object(forKey: "tokenCostUsageEnabled") as? Bool ?? false
        self.randomBlinkEnabled = userDefaults.object(forKey: "randomBlinkEnabled") as? Bool ?? false
        let codexDisplayName = userDefaults.string(forKey: "codexDisplayName") ?? "Codex"
        self.codexDisplayName = codexDisplayName
        if userDefaults.string(forKey: "codexDisplayName") == nil {
            userDefaults.set(codexDisplayName, forKey: "codexDisplayName")
        }
        let codexHomePath = userDefaults.string(forKey: "codexHomePath") ?? "~/.codex"
        self.codexHomePath = codexHomePath
        if userDefaults.string(forKey: "codexHomePath") == nil {
            userDefaults.set(codexHomePath, forKey: "codexHomePath")
        }
        let codexOwnerDisplayName = userDefaults.string(forKey: "codexOwnerDisplayName") ?? "Codex (Owner)"
        self.codexOwnerDisplayName = codexOwnerDisplayName
        if userDefaults.string(forKey: "codexOwnerDisplayName") == nil {
            userDefaults.set(codexOwnerDisplayName, forKey: "codexOwnerDisplayName")
        }
        let codexOwnerHomePath = userDefaults.string(forKey: "codexOwnerHomePath") ?? "~/.codex-owner"
        self.codexOwnerHomePath = codexOwnerHomePath
        if userDefaults.string(forKey: "codexOwnerHomePath") == nil {
            userDefaults.set(codexOwnerHomePath, forKey: "codexOwnerHomePath")
        }
        let codexMemberDisplayName = userDefaults.string(forKey: "codexMemberDisplayName") ?? "Codex (Member)"
        self.codexMemberDisplayName = codexMemberDisplayName
        if userDefaults.string(forKey: "codexMemberDisplayName") == nil {
            userDefaults.set(codexMemberDisplayName, forKey: "codexMemberDisplayName")
        }
        let codexMemberHomePath = userDefaults.string(forKey: "codexMemberHomePath") ?? "~/.codex-member"
        self.codexMemberHomePath = codexMemberHomePath
        if userDefaults.string(forKey: "codexMemberHomePath") == nil {
            userDefaults.set(codexMemberHomePath, forKey: "codexMemberHomePath")
        }
        self.claudeWebExtrasEnabled = userDefaults.object(forKey: "claudeWebExtrasEnabled") as? Bool ?? false
        let creditsExtrasDefault = userDefaults.object(forKey: "showOptionalCreditsAndExtraUsage") as? Bool
        self.showOptionalCreditsAndExtraUsage = creditsExtrasDefault ?? true
        if creditsExtrasDefault == nil {
            self.userDefaults.set(true, forKey: "showOptionalCreditsAndExtraUsage")
        }
        let claudeSourceRaw = userDefaults.string(forKey: "claudeUsageDataSource")
        self.claudeUsageDataSourceRaw = claudeSourceRaw ?? ClaudeUsageDataSource.web.rawValue
        self.mergeIcons = userDefaults.object(forKey: "mergeIcons") as? Bool ?? true
        self.switcherShowsIcons = userDefaults.object(forKey: "switcherShowsIcons") as? Bool ?? true
        self.zaiAPIToken = (try? zaiTokenStore.loadToken()) ?? ""
        self.selectedMenuProviderRaw = userDefaults.string(forKey: "selectedMenuProvider")
        self.providerDetectionCompleted = userDefaults.object(
            forKey: "providerDetectionCompleted") as? Bool ?? false
        self.toggleStore = ProviderToggleStore(userDefaults: userDefaults)
        self.toggleStore.purgeLegacyKeys()
        LaunchAtLoginManager.setEnabled(self.launchAtLogin)
        self.runInitialProviderDetectionIfNeeded()
        self.applyTokenCostDefaultIfNeeded()
        if self.claudeUsageDataSource != .cli {
            self.claudeWebExtrasEnabled = false
        }
    }

    func orderedProviders() -> [UsageProvider] {
        Self.effectiveProviderOrder(raw: self.providerOrderRaw)
    }

    func moveProvider(fromOffsets: IndexSet, toOffset: Int) {
        var order = self.orderedProviders()
        order.move(fromOffsets: fromOffsets, toOffset: toOffset)
        self.providerOrderRaw = order.map(\.rawValue)
    }

    func isProviderEnabled(provider: UsageProvider, metadata: ProviderMetadata) -> Bool {
        _ = self.providerToggleRevision
        return self.toggleStore.isEnabled(metadata: metadata)
    }

    func setProviderEnabled(provider: UsageProvider, metadata: ProviderMetadata, enabled: Bool) {
        self.providerToggleRevision &+= 1
        self.toggleStore.setEnabled(enabled, metadata: metadata)
    }

    func rerunProviderDetection() {
        self.runInitialProviderDetectionIfNeeded(force: true)
    }

    // MARK: - Private

    func isCCUsageCostUsageEffectivelyEnabled(for provider: UsageProvider) -> Bool {
        self.ccusageCostUsageEnabled
            && (provider == .codex
                || provider == .codexOwner
                || provider == .codexMember
                || provider == .claude)
    }

    private static func effectiveProviderOrder(raw: [String]) -> [UsageProvider] {
        var seen: Set<UsageProvider> = []
        var ordered: [UsageProvider] = []

        for rawValue in raw {
            guard let provider = UsageProvider(rawValue: rawValue) else { continue }
            guard !seen.contains(provider) else { continue }
            seen.insert(provider)
            ordered.append(provider)
        }

        if ordered.isEmpty {
            ordered = UsageProvider.allCases
            seen = Set(ordered)
        }

        if !seen.contains(.factory), let zaiIndex = ordered.firstIndex(of: .zai) {
            ordered.insert(.factory, at: zaiIndex)
            seen.insert(.factory)
        }

        for provider in UsageProvider.allCases where !seen.contains(provider) {
            ordered.append(provider)
        }

        return ordered
    }

    private func runInitialProviderDetectionIfNeeded(force: Bool = false) {
        guard force || !self.providerDetectionCompleted else { return }
        guard let codexMeta = ProviderRegistry.shared.metadata[.codex],
              let claudeMeta = ProviderRegistry.shared.metadata[.claude],
              let geminiMeta = ProviderRegistry.shared.metadata[.gemini],
              let antigravityMeta = ProviderRegistry.shared.metadata[.antigravity] else { return }

        LoginShellPathCache.shared.captureOnce { [weak self] _ in
            Task { @MainActor in
                await self?.applyProviderDetection(
                    codexMeta: codexMeta,
                    claudeMeta: claudeMeta,
                    geminiMeta: geminiMeta,
                    antigravityMeta: antigravityMeta)
            }
        }
    }

    private func applyProviderDetection(
        codexMeta: ProviderMetadata,
        claudeMeta: ProviderMetadata,
        geminiMeta: ProviderMetadata,
        antigravityMeta: ProviderMetadata) async
    {
        guard !self.providerDetectionCompleted else { return }
        let codexInstalled = BinaryLocator.resolveCodexBinary() != nil
        let claudeInstalled = BinaryLocator.resolveClaudeBinary() != nil
        let geminiInstalled = BinaryLocator.resolveGeminiBinary() != nil
        let antigravityRunning = await AntigravityStatusProbe.isRunning()

        // If none installed, keep Codex enabled to match previous behavior.
        let noneInstalled = !codexInstalled && !claudeInstalled && !geminiInstalled && !antigravityRunning
        let enableCodex = codexInstalled || noneInstalled
        let enableClaude = claudeInstalled
        let enableGemini = geminiInstalled
        let enableAntigravity = antigravityRunning

        self.providerToggleRevision &+= 1
        self.toggleStore.setEnabled(enableCodex, metadata: codexMeta)
        self.toggleStore.setEnabled(enableClaude, metadata: claudeMeta)
        self.toggleStore.setEnabled(enableGemini, metadata: geminiMeta)
        self.toggleStore.setEnabled(enableAntigravity, metadata: antigravityMeta)
        self.providerDetectionCompleted = true
    }

    private func applyTokenCostDefaultIfNeeded() {
        // Settings are persisted in UserDefaults.standard.
        guard UserDefaults.standard.object(forKey: "tokenCostUsageEnabled") == nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let hasSources = await Task.detached(priority: .utility) {
                Self.hasAnyTokenCostUsageSources()
            }.value
            guard hasSources else { return }
            guard UserDefaults.standard.object(forKey: "tokenCostUsageEnabled") == nil else { return }
            self.ccusageCostUsageEnabled = true
        }
    }

    nonisolated static func hasAnyTokenCostUsageSources(
        env: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default) -> Bool
    {
        func hasAnyJsonl(in root: URL) -> Bool {
            guard fileManager.fileExists(atPath: root.path) else { return false }
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants])
            else { return false }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "jsonl" {
                return true
            }
            return false
        }

        let codexRoot: URL = {
            let raw = env["CODEX_HOME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let raw, !raw.isEmpty {
                return URL(fileURLWithPath: raw).appendingPathComponent("sessions", isDirectory: true)
            }
            return fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".codex", isDirectory: true)
                .appendingPathComponent("sessions", isDirectory: true)
        }()
        if hasAnyJsonl(in: codexRoot) { return true }

        let claudeRoots: [URL] = {
            if let env = env["CLAUDE_CONFIG_DIR"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !env.isEmpty
            {
                return env.split(separator: ",").map { part in
                    let raw = String(part).trimmingCharacters(in: .whitespacesAndNewlines)
                    let url = URL(fileURLWithPath: raw)
                    if url.lastPathComponent == "projects" {
                        return url
                    }
                    return url.appendingPathComponent("projects", isDirectory: true)
                }
            }

            let home = fileManager.homeDirectoryForCurrentUser
            return [
                home.appendingPathComponent(".config/claude/projects", isDirectory: true),
                home.appendingPathComponent(".claude/projects", isDirectory: true),
            ]
        }()

        return claudeRoots.contains(where: hasAnyJsonl(in:))
    }

    private func schedulePersistZaiAPIToken() {
        self.zaiTokenPersistTask?.cancel()
        let token = self.zaiAPIToken
        let tokenStore = self.zaiTokenStore
        self.zaiTokenPersistTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            let error: (any Error)? = await Task.detached(priority: .utility) { () -> (any Error)? in
                do {
                    try tokenStore.storeToken(token)
                    return nil
                } catch {
                    return error
                }
            }.value
            if let error {
                // Keep value in memory; persist best-effort.
                CodexBarLog.logger("zai-token-store").error("Failed to persist z.ai token: \(error)")
            }
        }
    }
}

// MARK: - Codex multi-account helpers

extension SettingsStore {
    func codexDisplayNameResolved(for provider: UsageProvider, fallback: String) -> String {
        let trimmed: String? = switch provider {
        case .codex:
            self.codexDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        case .codexOwner:
            self.codexOwnerDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        case .codexMember:
            self.codexMemberDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            nil
        }

        guard let trimmed, !trimmed.isEmpty else { return fallback }
        return trimmed
    }

    func codexEnvironment(for provider: UsageProvider) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        guard let home = self.codexHomePathResolved(for: provider) else { return env }
        env["CODEX_HOME"] = home
        return env
    }

    func resetCodexDisplayName(for provider: UsageProvider) {
        switch provider {
        case .codex:
            self.codexDisplayName = Self.defaultCodexDisplayName(for: provider)
        case .codexOwner:
            self.codexOwnerDisplayName = Self.defaultCodexDisplayName(for: provider)
        case .codexMember:
            self.codexMemberDisplayName = Self.defaultCodexDisplayName(for: provider)
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            return
        }
    }

    func resetCodexHomePath(for provider: UsageProvider) {
        switch provider {
        case .codex:
            self.codexHomePath = Self.defaultCodexHomePath(for: provider)
        case .codexOwner:
            self.codexOwnerHomePath = Self.defaultCodexHomePath(for: provider)
        case .codexMember:
            self.codexMemberHomePath = Self.defaultCodexHomePath(for: provider)
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            return
        }
    }

    // MARK: - Private

    private func codexHomePathResolved(for provider: UsageProvider) -> String? {
        let raw: String? = switch provider {
        case .codex:
            self.codexHomePath
        case .codexOwner:
            self.codexOwnerHomePath
        case .codexMember:
            self.codexMemberHomePath
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            nil
        }

        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = Self.defaultCodexHomePath(for: provider)
        let expanded = Self.expandedHomePath(trimmed.isEmpty ? fallback : trimmed)
        return expanded.isEmpty ? nil : expanded
    }

    private static func defaultCodexDisplayName(for provider: UsageProvider) -> String {
        switch provider {
        case .codex:
            "Codex"
        case .codexOwner:
            "Codex (Owner)"
        case .codexMember:
            "Codex (Member)"
        case .claude:
            "Claude"
        case .factory:
            "Droid"
        case .zai:
            "z.ai"
        case .cursor:
            "Cursor"
        case .gemini:
            "Gemini"
        case .antigravity:
            "Antigravity"
        }
    }

    private static func defaultCodexHomePath(for provider: UsageProvider) -> String {
        switch provider {
        case .codex:
            "~/.codex"
        case .codexOwner:
            "~/.codex-owner"
        case .codexMember:
            "~/.codex-member"
        case .claude, .factory, .zai, .cursor, .gemini, .antigravity:
            "~/.codex"
        }
    }

    private static func expandedHomePath(_ raw: String) -> String {
        (raw as NSString).expandingTildeInPath
    }
}

enum LaunchAtLoginManager {
    @MainActor
    static func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13, *) else { return }
        let service = SMAppService.mainApp
        if enabled {
            try? service.register()
        } else {
            try? service.unregister()
        }
    }
}
