import CodexBarCore
import Foundation

@MainActor
struct MenuDescriptor {
    struct Section {
        var entries: [Entry]
    }

    enum Entry {
        case text(String, TextStyle)
        case action(String, MenuAction)
        case divider
    }

    enum MenuActionSystemImage: String {
        case refresh = "arrow.clockwise"
        case dashboard = "chart.bar"
        case statusPage = "waveform.path.ecg"
        case switchAccount = "key"
        case settings = "gearshape"
        case about = "info.circle"
        case quit = "xmark.rectangle"
        case copyError = "doc.on.doc"
    }

    enum TextStyle {
        case headline
        case primary
        case secondary
    }

    enum MenuAction {
        case installUpdate
        case refresh
        case dashboard
        case statusPage
        case switchAccount(UsageProvider)
        case settings
        case about
        case quit
        case copyError(String)
    }

    var sections: [Section]

    static func build(
        provider: UsageProvider?,
        store: UsageStore,
        settings: SettingsStore,
        account: AccountInfo,
        updateReady: Bool) -> MenuDescriptor
    {
        var sections: [Section] = []
        let language = settings.appLanguage

        switch provider {
        case .codex?:
            sections.append(Self.usageSection(for: .codex, store: store, settings: settings, language: language))
            sections.append(Self.accountSection(
                claude: nil,
                codex: store.snapshot(for: .codex),
                account: account,
                preferClaude: false,
                language: language))
        case .claude?:
            sections.append(Self.usageSection(for: .claude, store: store, settings: settings, language: language))
            sections.append(Self.accountSection(
                claude: store.snapshot(for: .claude),
                codex: store.snapshot(for: .codex),
                account: account,
                preferClaude: true,
                language: language))
        case .zai?:
            sections.append(Self.usageSection(for: .zai, store: store, settings: settings, language: language))
            sections.append(Self.accountSectionForSnapshot(store.snapshot(for: .zai), language: language))
        case .gemini?:
            sections.append(Self.usageSection(for: .gemini, store: store, settings: settings, language: language))
            sections.append(Self.accountSection(
                claude: nil,
                codex: nil,
                account: account,
                preferClaude: false,
                language: language))
        case .antigravity?:
            sections.append(Self.usageSection(for: .antigravity, store: store, settings: settings, language: language))
            sections.append(Self.accountSectionForSnapshot(store.snapshot(for: .antigravity), language: language))
        case .cursor?:
            sections.append(Self.usageSection(for: .cursor, store: store, settings: settings, language: language))
            sections.append(Self.accountSectionForSnapshot(store.snapshot(for: .cursor), language: language))
        case .factory?:
            sections.append(Self.usageSection(for: .factory, store: store, settings: settings, language: language))
            sections.append(Self.accountSectionForSnapshot(store.snapshot(for: .factory), language: language))
        case nil:
            var addedUsage = false
            for enabledProvider in store.enabledProviders() {
                sections.append(Self.usageSection(
                    for: enabledProvider,
                    store: store,
                    settings: settings,
                    language: language))
                addedUsage = true
            }
            if addedUsage {
                sections.append(Self.accountSection(
                    claude: store.snapshot(for: .claude),
                    codex: store.snapshot(for: .codex),
                    account: account,
                    preferClaude: store.isEnabled(.claude),
                    language: language))
            } else {
                let l10n = AppLocalization(language: language)
                sections.append(Section(entries: [.text(l10n.choose(
                    "No usage configured.",
                    "使用量の設定がありません。"), .secondary)]))
            }
        }

        let actions = Self.actionsSection(for: provider, store: store, language: language)
        if !actions.entries.isEmpty {
            sections.append(actions)
        }
        sections.append(Self.metaSection(updateReady: updateReady, language: language))

        return MenuDescriptor(sections: sections)
    }

    private static func usageSection(
        for provider: UsageProvider,
        store: UsageStore,
        settings: SettingsStore,
        language: AppLanguage) -> Section
    {
        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        let meta = store.metadata(for: provider)
        var entries: [Entry] = []
        let headlineText: String = {
            let name = external.providerName(provider)
            if let ver = Self.versionNumber(for: provider, store: store) { return "\(name) \(ver)" }
            return name
        }()
        entries.append(.text(headlineText, .headline))

        if let snap = store.snapshot(for: provider) {
            let sessionLabel = external.localizedProviderLabel(meta.sessionLabel)
            Self.appendRateWindow(
                entries: &entries,
                title: sessionLabel,
                window: snap.primary,
                language: language)
            if let weekly = snap.secondary {
                let weeklyLabel = external.localizedProviderLabel(meta.weeklyLabel)
                Self.appendRateWindow(
                    entries: &entries,
                    title: weeklyLabel,
                    window: weekly,
                    language: language)
                if let paceText = UsagePaceText.weekly(
                    provider: provider,
                    window: weekly,
                    language: language)
                {
                    entries.append(.text(paceText, .secondary))
                }
            } else if provider == .claude {
                entries.append(.text(l10n.choose(
                    "Weekly usage unavailable for this account.",
                    "このアカウントでは週次の使用量が利用できません。"), .secondary))
            }
            if meta.supportsOpus, let opus = snap.tertiary {
                let opusLabel = external.localizedProviderLabel(meta.opusLabel ?? "Sonnet")
                Self.appendRateWindow(
                    entries: &entries,
                    title: opusLabel,
                    window: opus,
                    language: language)
            }

            if settings.showOptionalCreditsAndExtraUsage,
               provider == .claude,
               let cost = snap.providerCost
            {
                let used = UsageFormatter.currencyString(
                    cost.used,
                    currencyCode: cost.currencyCode,
                    language: language)
                let limit = UsageFormatter.currencyString(
                    cost.limit,
                    currencyCode: cost.currencyCode,
                    language: language)
                entries.append(.text(l10n.choose(
                    "Extra usage: \(used) / \(limit)",
                    "追加使用量: \(used) / \(limit)"), .primary))
            }

            if provider == .cursor, let cost = snap.providerCost {
                let used = UsageFormatter.currencyString(
                    cost.used,
                    currencyCode: cost.currencyCode,
                    language: language)
                if cost.limit > 0 {
                    let limitStr = UsageFormatter.currencyString(
                        cost.limit,
                        currencyCode: cost.currencyCode,
                        language: language)
                    entries.append(.text(l10n.choose(
                        "On-Demand: \(used) / \(limitStr)",
                        "オンデマンド: \(used) / \(limitStr)"), .primary))
                } else {
                    entries.append(.text(l10n.choose(
                        "On-Demand: \(used)",
                        "オンデマンド: \(used)"), .primary))
                }
            }
        } else {
            entries.append(.text(l10n.choose("No usage yet", "まだ使用量がありません"), .secondary))
            if let err = store.error(for: provider), !err.isEmpty {
                let localized = external.localizedErrorMessage(err)
                let title = UsageFormatter.truncatedSingleLine(localized, max: 80)
                entries.append(.action(title, .copyError(localized)))
            }
        }

        if settings.showOptionalCreditsAndExtraUsage,
           meta.supportsCredits,
           provider == .codex
        {
            if let credits = store.credits {
                let creditsText = UsageFormatter.creditsString(
                    from: credits.remaining,
                    language: language)
                entries.append(.text(l10n.choose(
                    "Credits: \(creditsText)",
                    "クレジット: \(creditsText)"), .primary))
                if let latest = credits.events.first {
                    let summary = UsageFormatter.creditEventSummary(latest, language: language)
                    entries.append(.text(l10n.choose(
                        "Last spend: \(summary)",
                        "直近の利用: \(summary)"), .secondary))
                }
            } else {
                let hint = store.lastCreditsError ?? meta.creditsHint
                let localized = external.localizedErrorMessage(hint)
                entries.append(.text(localized, .secondary))
            }
        }

        return Section(entries: entries)
    }

    private static func accountSectionForSnapshot(_ snapshot: UsageSnapshot?, language: AppLanguage) -> Section {
        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        var entries: [Entry] = []
        let emailText = snapshot?.accountEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountLabel = l10n.choose("Account", "アカウント")
        let unknown = l10n.choose("Unknown", "不明")
        entries.append(.text("\(accountLabel): \(emailText?.isEmpty == false ? emailText! : unknown)", .secondary))

        if let plan = snapshot?.loginMethod, !plan.isEmpty {
            let planText = external.localizedPlanName(AccountFormatter.plan(plan))
            let planLabel = l10n.choose("Plan", "プラン")
            entries.append(.text("\(planLabel): \(planText)", .secondary))
        }
        return Section(entries: entries)
    }

    /// Builds the account section.
    /// - Claude snapshot is preferred when `preferClaude` is true.
    /// - Otherwise Codex snapshot wins; falls back to stored auth info.
    private static func accountSection(
        claude: UsageSnapshot?,
        codex: UsageSnapshot?,
        account: AccountInfo,
        preferClaude: Bool,
        language: AppLanguage) -> Section
    {
        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        var entries: [Entry] = []
        let emailFromClaude = claude?.accountEmail
        let emailFromCodex = codex?.accountEmail
        let planFromClaude = claude?.loginMethod
        let planFromCodex = codex?.loginMethod

        // Email: Claude wins when requested; otherwise Codex snapshot then auth.json fallback.
        let emailText: String = {
            if preferClaude, let e = emailFromClaude, !e.isEmpty { return e }
            if let e = emailFromCodex, !e.isEmpty { return e }
            if let codexEmail = account.email, !codexEmail.isEmpty { return codexEmail }
            if let e = emailFromClaude, !e.isEmpty { return e }
            return l10n.choose("Unknown", "不明")
        }()
        let accountLabel = l10n.choose("Account", "アカウント")
        entries.append(.text("\(accountLabel): \(emailText)", .secondary))

        // Plan: show only Claude plan when in Claude mode; otherwise Codex plan.
        if preferClaude {
            if let plan = planFromClaude, !plan.isEmpty {
                let planText = external.localizedPlanName(AccountFormatter.plan(plan))
                let planLabel = l10n.choose("Plan", "プラン")
                entries.append(.text("\(planLabel): \(planText)", .secondary))
            }
        } else if let plan = planFromCodex, !plan.isEmpty {
            let planText = external.localizedPlanName(AccountFormatter.plan(plan))
            let planLabel = l10n.choose("Plan", "プラン")
            entries.append(.text("\(planLabel): \(planText)", .secondary))
        } else if let plan = account.plan, !plan.isEmpty {
            let planText = external.localizedPlanName(AccountFormatter.plan(plan))
            let planLabel = l10n.choose("Plan", "プラン")
            entries.append(.text("\(planLabel): \(planText)", .secondary))
        }

        return Section(entries: entries)
    }

    private static func actionsSection(
        for provider: UsageProvider?,
        store: UsageStore,
        language: AppLanguage) -> Section
    {
        let l10n = AppLocalization(language: language)
        var entries: [Entry] = []
        let targetProvider = provider ?? store.enabledProviders().first
        let metadata = targetProvider.map { store.metadata(for: $0) }

        // Show "Add Account" if no account, "Switch Account" if logged in
        if (provider ?? store.enabledProviders().first) != .antigravity,
           (provider ?? store.enabledProviders().first) != .zai
        {
            let loginAction = self.switchAccountTarget(for: provider, store: store)
            let hasAccount = self.hasAccount(for: provider, store: store)
            let accountLabel = hasAccount
                ? l10n.choose("Switch Account...", "アカウントを切り替え...")
                : l10n.choose("Add Account...", "アカウントを追加...")
            entries.append(.action(accountLabel, loginAction))
        }

        if let dashboardTarget = targetProvider,
           dashboardTarget == .codex || dashboardTarget == .claude || dashboardTarget == .cursor ||
           dashboardTarget == .factory
        {
            entries.append(.action(l10n.choose("Usage Dashboard", "使用量ダッシュボード"), .dashboard))
        }
        if metadata?.statusPageURL != nil || metadata?.statusLinkURL != nil {
            entries.append(.action(l10n.choose("Status Page", "ステータスページ"), .statusPage))
        }

        if let statusLine = self.statusLine(for: provider, store: store, language: language) {
            entries.append(.text(statusLine, .secondary))
        }

        return Section(entries: entries)
    }

    private static func metaSection(updateReady: Bool, language: AppLanguage) -> Section {
        let l10n = AppLocalization(language: language)
        var entries: [Entry] = []
        if updateReady {
            entries.append(.action(l10n.choose(
                "Update ready, restart now?",
                "更新の準備ができました。再起動しますか？"), .installUpdate))
        }
        entries.append(contentsOf: [
            .action(l10n.choose("Settings...", "設定..."), .settings),
            .action(l10n.choose("About CodexBar", "CodexBarについて"), .about),
            .action(l10n.choose("Quit", "終了"), .quit),
        ])
        return Section(entries: entries)
    }

    private static func statusLine(
        for provider: UsageProvider?,
        store: UsageStore,
        language: AppLanguage) -> String?
    {
        let external = ExternalTextLocalizer(language: language)
        let target = provider ?? store.enabledProviders().first
        guard let target,
              let status = store.status(for: target),
              status.indicator != .none else { return nil }

        let description = status.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let indicatorLabel = status.indicator.label(language: language)
        let rawLabel = description?.isEmpty == false ? description! : indicatorLabel
        let label = external.localizedStatusDescription(rawLabel)
        if let updated = status.updatedAt {
            let freshness = UsageFormatter.updatedString(from: updated, language: language)
            return "\(label) — \(freshness)"
        }
        return label
    }

    private static func switchAccountTarget(for provider: UsageProvider?, store: UsageStore) -> MenuAction {
        if let provider { return .switchAccount(provider) }
        if let enabled = store.enabledProviders().first { return .switchAccount(enabled) }
        return .switchAccount(.codex)
    }

    private static func hasAccount(for provider: UsageProvider?, store: UsageStore) -> Bool {
        let target = provider ?? store.enabledProviders().first ?? .codex
        return store.snapshot(for: target)?.accountEmail != nil
    }

    private static func appendRateWindow(
        entries: inout [Entry],
        title: String,
        window: RateWindow,
        language: AppLanguage)
    {
        let l10n = AppLocalization(language: language)
        let line = UsageFormatter
            .usageLine(
                remaining: window.remainingPercent,
                used: window.usedPercent,
                language: language)
        entries.append(.text("\(title): \(line)", .primary))
        if let date = window.resetsAt {
            let countdown = UsageFormatter.resetCountdownDescription(from: date, language: language)
            let resetText = l10n.choose("Resets \(countdown)", "リセット: \(countdown)")
            entries.append(.text(resetText, .secondary))
        } else if let reset = window.resetDescription {
            let localized = Self.localizedResetDescription(reset, language: language)
            entries.append(.text(Self.resetLine(localized, language: language), .secondary))
        }
    }

    private static func localizedResetDescription(_ text: String, language: AppLanguage) -> String {
        guard language == .japanese else { return text }
        return text
            .replacingOccurrences(of: "tomorrow", with: "明日", options: [.caseInsensitive])
            .replacingOccurrences(of: "now", with: "いま", options: [.caseInsensitive])
            .replacingOccurrences(of: "in ", with: "あと", options: [.caseInsensitive])
    }

    private static func resetLine(_ reset: String, language: AppLanguage) -> String {
        let trimmed = reset.trimmingCharacters(in: .whitespacesAndNewlines)
        if language == .english {
            if trimmed.lowercased().hasPrefix("resets") { return trimmed }
            return "Resets \(trimmed)"
        }
        if trimmed.hasPrefix("リセット") { return trimmed }
        return "リセット: \(trimmed)"
    }

    private static func versionNumber(for provider: UsageProvider, store: UsageStore) -> String? {
        guard let raw = store.version(for: provider) else { return nil }
        let pattern = #"[0-9]+(?:\.[0-9]+)*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        guard let match = regex.firstMatch(in: raw, options: [], range: range),
              let r = Range(match.range, in: raw) else { return nil }
        return String(raw[r])
    }
}

private enum AccountFormatter {
    static func plan(_ text: String) -> String {
        let cleaned = UsageFormatter.cleanPlanName(text)
        return cleaned.isEmpty ? text : cleaned
    }

    static func email(_ text: String) -> String { text }
}

extension MenuDescriptor.MenuAction {
    var systemImageName: String? {
        switch self {
        case .installUpdate, .settings, .about, .quit:
            nil
        case .refresh: MenuDescriptor.MenuActionSystemImage.refresh.rawValue
        case .dashboard: MenuDescriptor.MenuActionSystemImage.dashboard.rawValue
        case .statusPage: MenuDescriptor.MenuActionSystemImage.statusPage.rawValue
        case .switchAccount: MenuDescriptor.MenuActionSystemImage.switchAccount.rawValue
        case .copyError: MenuDescriptor.MenuActionSystemImage.copyError.rawValue
        }
    }
}
