import AppKit
import CodexBarCore
import SwiftUI

/// SwiftUI card used inside the NSMenu to mirror Apple's rich menu panels.
struct UsageMenuCardView: View {
    struct Model {
        enum PercentStyle: String, Sendable {
            case left
            case used

            func labelSuffix(language: AppLanguage) -> String {
                switch self {
                case .left:
                    language == .japanese ? "残り" : "left"
                case .used:
                    language == .japanese ? "使用済み" : "used"
                }
            }

            func accessibilityLabel(language: AppLanguage) -> String {
                switch self {
                case .left:
                    language == .japanese ? "残りの使用量" : "Usage remaining"
                case .used:
                    language == .japanese ? "使用済みの使用量" : "Usage used"
                }
            }
        }

        struct Metric: Identifiable {
            let id: String
            let title: String
            let percent: Double
            let percentStyle: PercentStyle
            let resetText: String?
            let detailText: String?

            func percentLabel(language: AppLanguage) -> String {
                let value = String(format: "%.0f%%", self.percent)
                let suffix = self.percentStyle.labelSuffix(language: language)
                if language == .japanese {
                    return "\(suffix)\(value)"
                }
                return "\(value) \(suffix)"
            }
        }

        enum SubtitleStyle {
            case info
            case loading
            case error
        }

        struct TokenUsageSection: Sendable {
            let sessionLine: String
            let monthLine: String
            let hintLine: String?
            let errorLine: String?
            let errorCopyText: String?
        }

        struct ProviderCostSection: Sendable {
            let title: String
            let percentUsed: Double
            let spendLine: String
        }

        let providerName: String
        let email: String
        let subtitleText: String
        let subtitleStyle: SubtitleStyle
        let planText: String?
        let metrics: [Metric]
        let creditsText: String?
        let creditsRemaining: Double?
        let creditsHintText: String?
        let creditsHintCopyText: String?
        let providerCost: ProviderCostSection?
        let tokenUsage: TokenUsageSection?
        let placeholder: String?
        let progressColor: Color
        let language: AppLanguage
    }

    let model: Model
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    init(model: Model, width: CGFloat) {
        self.model = model
        self.width = width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            UsageMenuCardHeaderView(model: self.model)

            if self.hasDetails {
                Divider()
            }

            if self.model.metrics.isEmpty {
                if let placeholder = self.model.placeholder {
                    Text(placeholder)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .font(.subheadline)
                }
            } else {
                let hasUsage = !self.model.metrics.isEmpty
                let hasCredits = self.model.creditsText != nil
                let hasProviderCost = self.model.providerCost != nil
                let hasCost = self.model.tokenUsage != nil || hasProviderCost

                VStack(alignment: .leading, spacing: 12) {
                    if hasUsage {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(self.model.metrics) { metric in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(metric.title)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    UsageProgressBar(
                                        percent: metric.percent,
                                        tint: self.model.progressColor,
                                        accessibilityLabel: metric.percentStyle.accessibilityLabel(
                                            language: self.model.language))
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(metric.percentLabel(language: self.model.language))
                                            .font(.footnote)
                                        Spacer()
                                        if let reset = metric.resetText {
                                            Text(reset)
                                                .font(.footnote)
                                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                        }
                                    }
                                    if let detail = metric.detailText {
                                        Text(detail)
                                            .font(.footnote)
                                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    if hasUsage, hasCredits || hasCost {
                        Divider()
                    }
                    if let credits = self.model.creditsText {
                        CreditsBarContent(
                            creditsText: credits,
                            creditsRemaining: self.model.creditsRemaining,
                            hintText: self.model.creditsHintText,
                            hintCopyText: self.model.creditsHintCopyText,
                            progressColor: self.model.progressColor,
                            language: self.model.language)
                    }
                    if hasCredits, hasCost {
                        Divider()
                    }
                    if let providerCost = self.model.providerCost {
                        ProviderCostContent(
                            section: providerCost,
                            progressColor: self.model.progressColor,
                            language: self.model.language)
                    }
                    if hasProviderCost, self.model.tokenUsage != nil {
                        Divider()
                    }
                    if let tokenUsage = self.model.tokenUsage {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppLocalization(language: self.model.language).choose("Cost", "コスト"))
                                .font(.body)
                                .fontWeight(.medium)
                            Text(tokenUsage.sessionLine)
                                .font(.footnote)
                            Text(tokenUsage.monthLine)
                                .font(.footnote)
                            if let hint = tokenUsage.hintLine, !hint.isEmpty {
                                Text(hint)
                                    .font(.footnote)
                                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                    .lineLimit(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let error = tokenUsage.errorLine, !error.isEmpty {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(MenuHighlightStyle.error(self.isHighlighted))
                                    .lineLimit(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .overlay {
                                        ClickToCopyOverlay(copyText: tokenUsage.errorCopyText ?? error)
                                    }
                            }
                        }
                    }
                }
                .padding(.bottom, self.model.creditsText == nil ? 6 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 2)
        .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
    }

    private var hasDetails: Bool {
        !self.model.metrics.isEmpty || self.model.placeholder != nil || self.model.tokenUsage != nil ||
            self.model.providerCost != nil
    }
}

private struct UsageMenuCardHeaderView: View {
    let model: UsageMenuCardView.Model
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(self.model.providerName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(self.model.email)
                    .font(.subheadline)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
            let subtitleAlignment: VerticalAlignment = self.model.subtitleStyle == .error ? .top : .firstTextBaseline
            HStack(alignment: subtitleAlignment) {
                Text(self.model.subtitleText)
                    .font(.footnote)
                    .foregroundStyle(self.subtitleColor)
                    .lineLimit(self.model.subtitleStyle == .error ? 4 : 1)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .padding(.bottom, self.model.subtitleStyle == .error ? 2 : 0)
                Spacer()
                if let plan = self.model.planText {
                    Text(plan)
                        .font(.footnote)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
            }
        }
    }

    private var subtitleColor: Color {
        switch self.model.subtitleStyle {
        case .info: MenuHighlightStyle.secondary(self.isHighlighted)
        case .loading: MenuHighlightStyle.secondary(self.isHighlighted)
        case .error: MenuHighlightStyle.error(self.isHighlighted)
        }
    }
}

private struct ProviderCostContent: View {
    let section: UsageMenuCardView.Model.ProviderCostSection
    let progressColor: Color
    let language: AppLanguage
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        let l10n = AppLocalization(language: self.language)
        VStack(alignment: .leading, spacing: 6) {
            Text(self.section.title)
                .font(.body)
                .fontWeight(.medium)
            UsageProgressBar(
                percent: self.section.percentUsed,
                tint: self.progressColor,
                accessibilityLabel: l10n.choose("Extra usage spent", "追加使用量の利用済み"))
            HStack(alignment: .firstTextBaseline) {
                Text(self.section.spendLine)
                    .font(.footnote)
                Spacer()
                let percentText = String(format: "%.0f%%", min(100, max(0, self.section.percentUsed)))
                Text(l10n.choose("\(percentText) used", "使用済み\(percentText)"))
                    .font(.footnote)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
        }
    }
}

struct UsageMenuCardHeaderSectionView: View {
    let model: UsageMenuCardView.Model
    let showDivider: Bool
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            UsageMenuCardHeaderView(model: self.model)

            if self.showDivider {
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
    }
}

struct UsageMenuCardUsageSectionView: View {
    let model: UsageMenuCardView.Model
    let showBottomDivider: Bool
    let bottomPadding: CGFloat
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if self.model.metrics.isEmpty {
                if let placeholder = self.model.placeholder {
                    Text(placeholder)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .font(.subheadline)
                }
            } else {
                ForEach(self.model.metrics) { metric in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metric.title)
                            .font(.body)
                            .fontWeight(.medium)
                        UsageProgressBar(
                            percent: metric.percent,
                            tint: self.model.progressColor,
                            accessibilityLabel: metric.percentStyle.accessibilityLabel(
                                language: self.model.language))
                        HStack(alignment: .firstTextBaseline) {
                            Text(metric.percentLabel(language: self.model.language))
                                .font(.footnote)
                            Spacer()
                            if let reset = metric.resetText {
                                Text(reset)
                                    .font(.footnote)
                                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            }
                        }
                        if let detail = metric.detailText {
                            Text(detail)
                                .font(.footnote)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                        }
                    }
                }
            }
            if self.showBottomDivider {
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, self.bottomPadding)
        .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
    }
}

struct UsageMenuCardCreditsSectionView: View {
    let model: UsageMenuCardView.Model
    let showBottomDivider: Bool
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let width: CGFloat

    init(
        model: UsageMenuCardView.Model,
        showBottomDivider: Bool,
        topPadding: CGFloat,
        bottomPadding: CGFloat,
        width: CGFloat)
    {
        self.model = model
        self.showBottomDivider = showBottomDivider
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.width = width
    }

    var body: some View {
        if let credits = self.model.creditsText {
            VStack(alignment: .leading, spacing: 6) {
                CreditsBarContent(
                    creditsText: credits,
                    creditsRemaining: self.model.creditsRemaining,
                    hintText: self.model.creditsHintText,
                    hintCopyText: self.model.creditsHintCopyText,
                    progressColor: self.model.progressColor,
                    language: self.model.language)
                if self.showBottomDivider {
                    Divider()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, self.topPadding)
            .padding(.bottom, self.bottomPadding)
            .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CreditsBarContent: View {
    private static let fullScaleTokens: Double = 1000

    let creditsText: String
    let creditsRemaining: Double?
    let hintText: String?
    let hintCopyText: String?
    let progressColor: Color
    let language: AppLanguage
    @Environment(\.menuItemHighlighted) private var isHighlighted

    private var percentLeft: Double? {
        guard let creditsRemaining else { return nil }
        let percent = (creditsRemaining / Self.fullScaleTokens) * 100
        return min(100, max(0, percent))
    }

    private var scaleText: String {
        let scale = UsageFormatter.tokenCountString(Int(Self.fullScaleTokens), language: self.language)
        let l10n = AppLocalization(language: self.language)
        return l10n.choose("\(scale) tokens", "\(scale) トークン")
    }

    var body: some View {
        let l10n = AppLocalization(language: self.language)
        VStack(alignment: .leading, spacing: 6) {
            Text(l10n.choose("Credits", "クレジット"))
                .font(.body)
                .fontWeight(.medium)
            if let percentLeft {
                UsageProgressBar(
                    percent: percentLeft,
                    tint: self.progressColor,
                    accessibilityLabel: l10n.choose("Credits remaining", "クレジット残量"))
                HStack(alignment: .firstTextBaseline) {
                    Text(self.creditsText)
                        .font(.caption)
                    Spacer()
                    Text(self.scaleText)
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                }
            } else {
                Text(self.creditsText)
                    .font(.caption)
            }
            if let hintText, !hintText.isEmpty {
                Text(hintText)
                    .font(.footnote)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay {
                        ClickToCopyOverlay(copyText: self.hintCopyText ?? hintText)
                    }
            }
        }
    }
}

struct UsageMenuCardCostSectionView: View {
    let model: UsageMenuCardView.Model
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        let l10n = AppLocalization(language: self.model.language)
        let hasTokenCost = self.model.tokenUsage != nil
        return Group {
            if hasTokenCost {
                VStack(alignment: .leading, spacing: 10) {
                    if let tokenUsage = self.model.tokenUsage {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(l10n.choose("Cost", "コスト"))
                                .font(.body)
                                .fontWeight(.medium)
                            Text(tokenUsage.sessionLine)
                                .font(.caption)
                            Text(tokenUsage.monthLine)
                                .font(.caption)
                            if let hint = tokenUsage.hintLine, !hint.isEmpty {
                                Text(hint)
                                    .font(.footnote)
                                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                    .lineLimit(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let error = tokenUsage.errorLine, !error.isEmpty {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(MenuHighlightStyle.error(self.isHighlighted))
                                    .lineLimit(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .overlay {
                                        ClickToCopyOverlay(copyText: tokenUsage.errorCopyText ?? error)
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, self.topPadding)
                .padding(.bottom, self.bottomPadding)
                .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct UsageMenuCardExtraUsageSectionView: View {
    let model: UsageMenuCardView.Model
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let width: CGFloat

    var body: some View {
        Group {
            if let providerCost = self.model.providerCost {
                ProviderCostContent(
                    section: providerCost,
                    progressColor: self.model.progressColor,
                    language: self.model.language)
                    .padding(.horizontal, 16)
                    .padding(.top, self.topPadding)
                    .padding(.bottom, self.bottomPadding)
                    .frame(minWidth: self.width, maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Model factory

extension UsageMenuCardView.Model {
    struct Input {
        let provider: UsageProvider
        let metadata: ProviderMetadata
        let snapshot: UsageSnapshot?
        let credits: CreditsSnapshot?
        let creditsError: String?
        let dashboard: OpenAIDashboardSnapshot?
        let dashboardError: String?
        let tokenSnapshot: CCUsageTokenSnapshot?
        let tokenError: String?
        let account: AccountInfo
        let isRefreshing: Bool
        let lastError: String?
        let usageBarsShowUsed: Bool
        let tokenCostUsageEnabled: Bool
        let showOptionalCreditsAndExtraUsage: Bool
        let now: Date
        let language: AppLanguage
    }

    static func make(_ input: Input) -> UsageMenuCardView.Model {
        let l10n = AppLocalization(language: input.language)
        let email = Self.email(
            for: input.provider,
            snapshot: input.snapshot,
            account: input.account)
        let planText = Self.plan(
            for: input.provider,
            snapshot: input.snapshot,
            account: input.account,
            language: input.language)
        let metrics = Self.metrics(input: input, language: input.language)
        let creditsText: String? = if input.provider == .codex, !input.showOptionalCreditsAndExtraUsage {
            nil
        } else {
            Self.creditsLine(
                metadata: input.metadata,
                credits: input.credits,
                error: input.creditsError,
                language: input.language)
        }
        let creditsHintText = Self.dashboardHint(
            provider: input.provider,
            error: input.dashboardError,
            language: input.language)
        let providerCost: ProviderCostSection? = if input.provider == .claude, !input.showOptionalCreditsAndExtraUsage {
            nil
        } else {
            Self.providerCostSection(
                provider: input.provider,
                cost: input.snapshot?.providerCost,
                language: input.language)
        }
        let tokenUsage = Self.tokenUsageSection(
            provider: input.provider,
            enabled: input.tokenCostUsageEnabled,
            snapshot: input.tokenSnapshot,
            error: input.tokenError,
            language: input.language)
        let subtitle = Self.subtitle(
            snapshot: input.snapshot,
            isRefreshing: input.isRefreshing,
            lastError: input.lastError,
            language: input.language)
        let placeholder = input.snapshot == nil && !input.isRefreshing && input.lastError == nil
            ? l10n.choose("No usage yet", "まだ使用量がありません")
            : nil

        return UsageMenuCardView.Model(
            providerName: input.metadata.displayName,
            email: email,
            subtitleText: subtitle.text,
            subtitleStyle: subtitle.style,
            planText: planText,
            metrics: metrics,
            creditsText: creditsText,
            creditsRemaining: input.credits?.remaining,
            creditsHintText: creditsHintText,
            creditsHintCopyText: (creditsHintText?.isEmpty ?? true) ? nil : creditsHintText,
            providerCost: providerCost,
            tokenUsage: tokenUsage,
            placeholder: placeholder,
            progressColor: Self.progressColor(for: input.provider),
            language: input.language)
    }

    private static func email(
        for provider: UsageProvider,
        snapshot: UsageSnapshot?,
        account: AccountInfo) -> String
    {
        switch provider {
        case .codex:
            if let email = snapshot?.accountEmail, !email.isEmpty { return email }
            if let email = account.email, !email.isEmpty { return email }
        case .codexOwner, .codexMember:
            if let email = snapshot?.accountEmail, !email.isEmpty { return email }
        case .claude, .zai, .gemini, .antigravity, .cursor, .factory:
            if let email = snapshot?.accountEmail, !email.isEmpty { return email }
        }
        return ""
    }

    private static func plan(
        for provider: UsageProvider,
        snapshot: UsageSnapshot?,
        account: AccountInfo,
        language: AppLanguage) -> String?
    {
        switch provider {
        case .codex:
            if let plan = snapshot?.loginMethod, !plan.isEmpty { return self.planDisplay(plan, language: language) }
            if let plan = account.plan, !plan.isEmpty { return Self.planDisplay(plan, language: language) }
        case .codexOwner, .codexMember:
            if let plan = snapshot?.loginMethod, !plan.isEmpty { return self.planDisplay(plan, language: language) }
        case .claude, .zai, .gemini, .antigravity, .cursor, .factory:
            if let plan = snapshot?.loginMethod, !plan.isEmpty { return self.planDisplay(plan, language: language) }
        }
        return nil
    }

    private static func planDisplay(_ text: String, language: AppLanguage) -> String {
        let external = ExternalTextLocalizer(language: language)
        let cleaned = UsageFormatter.cleanPlanName(text)
        let base = cleaned.isEmpty ? text : cleaned
        return external.localizedPlanName(base)
    }

    private static func subtitle(
        snapshot: UsageSnapshot?,
        isRefreshing: Bool,
        lastError: String?,
        language: AppLanguage) -> (text: String, style: SubtitleStyle)
    {
        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        if let lastError, !lastError.isEmpty {
            let localized = external.localizedErrorMessage(lastError)
            return (localized.trimmingCharacters(in: .whitespacesAndNewlines), .error)
        }

        if isRefreshing, snapshot == nil {
            return (l10n.choose("Refreshing...", "更新中..."), .loading)
        }

        if let updated = snapshot?.updatedAt {
            return (UsageFormatter.updatedString(from: updated, language: language), .info)
        }

        return (l10n.choose("Not fetched yet", "まだ取得していません"), .info)
    }

    private static func metrics(input: Input, language: AppLanguage) -> [Metric] {
        guard let snapshot = input.snapshot else { return [] }
        let external = ExternalTextLocalizer(language: language)
        var metrics: [Metric] = []
        let percentStyle: PercentStyle = input.usageBarsShowUsed ? .used : .left
        let zaiUsage = input.provider == .zai ? snapshot.zaiUsage : nil
        let zaiTokenDetail = Self.zaiLimitDetailText(limit: zaiUsage?.tokenLimit, language: language)
        let zaiTimeDetail = Self.zaiLimitDetailText(limit: zaiUsage?.timeLimit, language: language)
        metrics.append(Metric(
            id: "primary",
            title: external.localizedProviderLabel(input.metadata.sessionLabel),
            percent: Self.clamped(
                input.usageBarsShowUsed ? snapshot.primary.usedPercent : snapshot.primary.remainingPercent),
            percentStyle: percentStyle,
            resetText: Self.resetText(for: snapshot.primary, prefersCountdown: true, language: language),
            detailText: input.provider == .zai ? zaiTokenDetail : nil))
        if let weekly = snapshot.secondary {
            let paceText = UsagePaceText.weekly(
                provider: input.provider,
                window: weekly,
                now: input.now,
                language: language)
            metrics.append(Metric(
                id: "secondary",
                title: external.localizedProviderLabel(input.metadata.weeklyLabel),
                percent: Self.clamped(input.usageBarsShowUsed ? weekly.usedPercent : weekly.remainingPercent),
                percentStyle: percentStyle,
                resetText: Self.resetText(for: weekly, prefersCountdown: true, language: language),
                detailText: input.provider == .zai ? zaiTimeDetail : paceText))
        }
        if input.metadata.supportsOpus, let opus = snapshot.tertiary {
            metrics.append(Metric(
                id: "tertiary",
                title: external.localizedProviderLabel(input.metadata.opusLabel ?? "Sonnet"),
                percent: Self.clamped(input.usageBarsShowUsed ? opus.usedPercent : opus.remainingPercent),
                percentStyle: percentStyle,
                resetText: Self.resetText(for: opus, prefersCountdown: true, language: language),
                detailText: nil))
        }

        if input.provider == .codex, let remaining = input.dashboard?.codeReviewRemainingPercent {
            let percent = input.usageBarsShowUsed ? (100 - remaining) : remaining
            metrics.append(Metric(
                id: "code-review",
                title: AppLocalization(language: language).choose("Code review", "コードレビュー"),
                percent: Self.clamped(percent),
                percentStyle: percentStyle,
                resetText: nil,
                detailText: nil))
        }
        return metrics
    }

    private static func zaiLimitDetailText(limit: ZaiLimitEntry?, language: AppLanguage) -> String? {
        guard let limit else { return nil }
        let l10n = AppLocalization(language: language)
        let currentStr = UsageFormatter.tokenCountString(limit.currentValue, language: language)
        let usageStr = UsageFormatter.tokenCountString(limit.usage, language: language)
        let remainingStr = UsageFormatter.tokenCountString(limit.remaining, language: language)
        return l10n.choose(
            "\(currentStr) / \(usageStr) (\(remainingStr) remaining)",
            "\(currentStr) / \(usageStr)（残り\(remainingStr)）")
    }

    private static func creditsLine(
        metadata: ProviderMetadata,
        credits: CreditsSnapshot?,
        error: String?,
        language: AppLanguage) -> String?
    {
        guard metadata.supportsCredits else { return nil }
        let external = ExternalTextLocalizer(language: language)
        if let credits {
            return UsageFormatter.creditsString(from: credits.remaining, language: language)
        }
        if let error, !error.isEmpty {
            let localized = external.localizedErrorMessage(error)
            return localized.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return external.localizedErrorMessage(metadata.creditsHint)
    }

    private static func dashboardHint(
        provider: UsageProvider,
        error: String?,
        language: AppLanguage) -> String?
    {
        guard provider == .codex else { return nil }
        guard let error, !error.isEmpty else { return nil }
        return ExternalTextLocalizer(language: language).localizedErrorMessage(error)
    }

    private static func tokenUsageSection(
        provider: UsageProvider,
        enabled: Bool,
        snapshot: CCUsageTokenSnapshot?,
        error: String?,
        language: AppLanguage) -> TokenUsageSection?
    {
        guard provider == .codex
            || provider == .codexOwner
            || provider == .codexMember
            || provider == .claude
        else { return nil }
        guard enabled else { return nil }
        guard let snapshot else { return nil }

        let l10n = AppLocalization(language: language)
        let external = ExternalTextLocalizer(language: language)
        let sessionCost = snapshot.sessionCostUSD.map {
            UsageFormatter.usdString($0, language: language)
        } ?? "—"
        let sessionTokens = snapshot.sessionTokens.map { UsageFormatter.tokenCountString($0, language: language) }
        let sessionLine: String = {
            if let sessionTokens {
                return l10n.choose(
                    "Today: \(sessionCost) · \(sessionTokens) tokens",
                    "今日: \(sessionCost) · \(sessionTokens) トークン")
            }
            return l10n.choose("Today: \(sessionCost)", "今日: \(sessionCost)")
        }()

        let monthCost = snapshot.last30DaysCostUSD.map {
            UsageFormatter.usdString($0, language: language)
        } ?? "—"
        let fallbackTokens = snapshot.daily.compactMap(\.totalTokens).reduce(0, +)
        let monthTokensValue = snapshot.last30DaysTokens ?? (fallbackTokens > 0 ? fallbackTokens : nil)
        let monthTokens = monthTokensValue.map { UsageFormatter.tokenCountString($0, language: language) }
        let monthLine: String = {
            if let monthTokens {
                return l10n.choose(
                    "Last 30 days: \(monthCost) · \(monthTokens) tokens",
                    "直近30日: \(monthCost) · \(monthTokens) トークン")
            }
            return l10n.choose("Last 30 days: \(monthCost)", "直近30日: \(monthCost)")
        }()
        let err = (error?.isEmpty ?? true) ? nil : external.localizedErrorMessage(error ?? "")
        return TokenUsageSection(
            sessionLine: sessionLine,
            monthLine: monthLine,
            hintLine: nil,
            errorLine: err,
            errorCopyText: (error?.isEmpty ?? true) ? nil : err)
    }

    private static func providerCostSection(
        provider: UsageProvider,
        cost: ProviderCostSnapshot?,
        language: AppLanguage) -> ProviderCostSection?
    {
        guard provider == .claude else { return nil }
        guard let cost else { return nil }
        guard cost.limit > 0 else { return nil }

        let l10n = AppLocalization(language: language)
        let used = UsageFormatter.currencyString(
            cost.used,
            currencyCode: cost.currencyCode,
            language: language)
        let limit = UsageFormatter.currencyString(
            cost.limit,
            currencyCode: cost.currencyCode,
            language: language)
        let percentUsed = Self.clamped((cost.used / cost.limit) * 100)

        return ProviderCostSection(
            title: l10n.choose("Extra usage", "追加使用量"),
            percentUsed: percentUsed,
            spendLine: l10n.choose("This month: \(used) / \(limit)", "今月: \(used) / \(limit)"))
    }

    private static func clamped(_ value: Double) -> Double {
        min(100, max(0, value))
    }

    private static func progressColor(for provider: UsageProvider) -> Color {
        switch provider {
        case .codex, .codexOwner, .codexMember:
            Color(red: 73 / 255, green: 163 / 255, blue: 176 / 255)
        case .claude:
            Color(red: 204 / 255, green: 124 / 255, blue: 94 / 255)
        case .zai:
            Color(red: 232 / 255, green: 90 / 255, blue: 106 / 255)
        case .gemini:
            Color(red: 171 / 255, green: 135 / 255, blue: 234 / 255) // #AB87EA
        case .antigravity:
            Color(red: 96 / 255, green: 186 / 255, blue: 126 / 255)
        case .cursor:
            Color(red: 0 / 255, green: 191 / 255, blue: 165 / 255) // #00BFA5 - Cursor teal
        case .factory:
            Color(red: 255 / 255, green: 107 / 255, blue: 53 / 255) // Factory orange
        }
    }

    private static func resetText(
        for window: RateWindow,
        prefersCountdown: Bool,
        language: AppLanguage) -> String?
    {
        let l10n = AppLocalization(language: language)
        if let date = window.resetsAt {
            if prefersCountdown {
                let countdown = UsageFormatter.resetCountdownDescription(from: date, language: language)
                return l10n.choose("Resets \(countdown)", "リセット: \(countdown)")
            }
            let reset = UsageFormatter.resetDescription(from: date, language: language)
            return l10n.choose("Resets \(reset)", "リセット: \(reset)")
        }

        if let desc = window.resetDescription, !desc.isEmpty {
            if language == .japanese {
                return desc
                    .replacingOccurrences(of: "tomorrow", with: "明日", options: [.caseInsensitive])
                    .replacingOccurrences(of: "now", with: "いま", options: [.caseInsensitive])
                    .replacingOccurrences(of: "in ", with: "あと", options: [.caseInsensitive])
            }
            return desc
        }
        return nil
    }
}

// MARK: - Copy-on-click overlay

private struct ClickToCopyOverlay: NSViewRepresentable {
    let copyText: String

    func makeNSView(context: Context) -> ClickToCopyView {
        ClickToCopyView(copyText: self.copyText)
    }

    func updateNSView(_ nsView: ClickToCopyView, context: Context) {
        nsView.copyText = self.copyText
    }
}

private final class ClickToCopyView: NSView {
    var copyText: String

    init(copyText: String) {
        self.copyText = copyText
        super.init(frame: .zero)
        self.wantsLayer = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        _ = event
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(self.copyText, forType: .string)
    }
}
