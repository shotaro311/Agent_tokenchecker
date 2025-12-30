import CodexBarCore
import SwiftUI
import WidgetKit

private struct WidgetLocalization {
    let language: AppLanguage
    let l10n: AppLocalization
    let external: ExternalTextLocalizer

    init(language: AppLanguage) {
        self.language = language
        self.l10n = AppLocalization(language: language)
        self.external = ExternalTextLocalizer(language: language)
    }

    static func current(bundleID: String? = Bundle.main.bundleIdentifier) -> WidgetLocalization {
        WidgetLocalization(language: AppLanguageStore.load(bundleID: bundleID))
    }

    func text(_ english: String, _ japanese: String) -> String {
        self.l10n.choose(english, japanese)
    }
}

struct CodexBarUsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodexBarWidgetEntry
    private var localization: WidgetLocalization { WidgetLocalization.current() }

    var body: some View {
        let providerEntry = self.entry.snapshot.entries.first { $0.provider == self.entry.provider }
        let localization = self.localization
        ZStack {
            Color.black.opacity(0.02)
            if let providerEntry {
                self.content(providerEntry: providerEntry, localization: localization)
            } else {
                self.emptyState(localization: localization)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func content(
        providerEntry: WidgetSnapshot.ProviderEntry,
        localization: WidgetLocalization) -> some View
    {
        switch self.family {
        case .systemSmall:
            SmallUsageView(entry: providerEntry, localization: localization)
        case .systemMedium:
            MediumUsageView(entry: providerEntry, localization: localization)
        default:
            LargeUsageView(entry: providerEntry, localization: localization)
        }
    }

    private func emptyState(localization: WidgetLocalization) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text("Open CodexBar", "CodexBarを開く"))
                .font(.body)
                .fontWeight(.semibold)
            Text(localization.text("Usage data will appear once the app refreshes.", "アプリが更新されると使用量が表示されます。"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

struct CodexBarHistoryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodexBarWidgetEntry
    private var localization: WidgetLocalization { WidgetLocalization.current() }

    var body: some View {
        let providerEntry = self.entry.snapshot.entries.first { $0.provider == self.entry.provider }
        let localization = self.localization
        ZStack {
            Color.black.opacity(0.02)
            if let providerEntry {
                HistoryView(entry: providerEntry, isLarge: self.family == .systemLarge, localization: localization)
            } else {
                self.emptyState(localization: localization)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func emptyState(localization: WidgetLocalization) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text("Open CodexBar", "CodexBarを開く"))
                .font(.body)
                .fontWeight(.semibold)
            Text(localization.text("Usage history will appear after a refresh.", "更新後に使用履歴が表示されます。"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

struct CodexBarCompactWidgetView: View {
    let entry: CodexBarCompactEntry
    private var localization: WidgetLocalization { WidgetLocalization.current() }

    var body: some View {
        let providerEntry = self.entry.snapshot.entries.first { $0.provider == self.entry.provider }
        let localization = self.localization
        ZStack {
            Color.black.opacity(0.02)
            if let providerEntry {
                CompactMetricView(entry: providerEntry, metric: self.entry.metric, localization: localization)
            } else {
                self.emptyState(localization: localization)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func emptyState(localization: WidgetLocalization) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text("Open CodexBar", "CodexBarを開く"))
                .font(.body)
                .fontWeight(.semibold)
            Text(localization.text("Usage data will appear once the app refreshes.", "アプリが更新されると使用量が表示されます。"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

struct CodexBarSwitcherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodexBarSwitcherEntry
    private var localization: WidgetLocalization { WidgetLocalization.current() }

    var body: some View {
        let providerEntry = self.entry.snapshot.entries.first { $0.provider == self.entry.provider }
        let localization = self.localization
        ZStack {
            Color.black.opacity(0.02)
            VStack(alignment: .leading, spacing: 10) {
                ProviderSwitcherRow(
                    providers: self.entry.availableProviders,
                    selected: self.entry.provider,
                    updatedAt: providerEntry?.updatedAt ?? Date(),
                    compact: self.family == .systemSmall,
                    showsTimestamp: self.family != .systemSmall,
                    localization: localization)
                if let providerEntry {
                    self.content(providerEntry: providerEntry, localization: localization)
                } else {
                    self.emptyState(localization: localization)
                }
            }
            .padding(12)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func content(
        providerEntry: WidgetSnapshot.ProviderEntry,
        localization: WidgetLocalization) -> some View
    {
        switch self.family {
        case .systemSmall:
            SwitcherSmallUsageView(entry: providerEntry, localization: localization)
        case .systemMedium:
            SwitcherMediumUsageView(entry: providerEntry, localization: localization)
        default:
            SwitcherLargeUsageView(entry: providerEntry, localization: localization)
        }
    }

    private func emptyState(localization: WidgetLocalization) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text("Open CodexBar", "CodexBarを開く"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(localization.text("Usage data appears after a refresh.", "更新後に使用量が表示されます。"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CompactMetricView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let metric: CompactMetric
    let localization: WidgetLocalization

    var body: some View {
        let display = self.display
        VStack(alignment: .leading, spacing: 8) {
            HeaderView(provider: self.entry.provider, updatedAt: self.entry.updatedAt, localization: self.localization)
            VStack(alignment: .leading, spacing: 2) {
                Text(display.value)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(display.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let detail = display.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }

    private var display: (value: String, label: String, detail: String?) {
        switch self.metric {
        case .credits:
            let value = self.entry.creditsRemaining
                .map { WidgetFormat.credits($0, language: self.localization.language) }
                ?? "—"
            return (value, self.localization.text("Credits left", "残りクレジット"), nil)
        case .todayCost:
            let value = self.entry.tokenUsage?.sessionCostUSD
                .map { WidgetFormat.usd($0, language: self.localization.language) }
                ?? "—"
            let detail = self.entry.tokenUsage?.sessionTokens
                .map { WidgetFormat.tokenCount($0, language: self.localization.language) }
            return (value, self.localization.text("Today cost", "今日のコスト"), detail)
        case .last30DaysCost:
            let value = self.entry.tokenUsage?.last30DaysCostUSD
                .map { WidgetFormat.usd($0, language: self.localization.language) }
                ?? "—"
            let detail = self.entry.tokenUsage?.last30DaysTokens
                .map { WidgetFormat.tokenCount($0, language: self.localization.language) }
            return (value, self.localization.text("30d cost", "30日間コスト"), detail)
        }
    }
}

private struct ProviderSwitcherRow: View {
    let providers: [UsageProvider]
    let selected: UsageProvider
    let updatedAt: Date
    let compact: Bool
    let showsTimestamp: Bool
    let localization: WidgetLocalization

    var body: some View {
        HStack(spacing: self.compact ? 4 : 6) {
            ForEach(self.providers, id: \.self) { provider in
                ProviderSwitchChip(
                    provider: provider,
                    selected: provider == self.selected,
                    compact: self.compact,
                    localization: self.localization)
            }
            if self.showsTimestamp {
                Spacer(minLength: 6)
                Text(WidgetFormat.relativeDate(self.updatedAt, language: self.localization.language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ProviderSwitchChip: View {
    let provider: UsageProvider
    let selected: Bool
    let compact: Bool
    let localization: WidgetLocalization

    var body: some View {
        let label = self.compact ? self.shortLabel : self.longLabel
        let background = self.selected
            ? WidgetColors.color(for: self.provider).opacity(0.2)
            : Color.primary.opacity(0.08)

        if let choice = ProviderChoice(provider: self.provider) {
            Button(intent: SwitchWidgetProviderIntent(provider: choice)) {
                Text(label)
                    .font(self.compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(self.selected ? Color.primary : Color.secondary)
                    .padding(.horizontal, self.compact ? 6 : 8)
                    .padding(.vertical, self.compact ? 3 : 4)
                    .background(Capsule().fill(background))
            }
            .buttonStyle(.plain)
        } else {
            Text(label)
                .font(self.compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(self.selected ? Color.primary : Color.secondary)
                .padding(.horizontal, self.compact ? 6 : 8)
                .padding(.vertical, self.compact ? 3 : 4)
                .background(Capsule().fill(background))
        }
    }

    private var longLabel: String {
        self.localization.external.providerName(self.provider)
    }

    private var shortLabel: String {
        self.localization.external.providerShortName(self.provider)
    }
}

private struct SwitcherSmallUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 8) {
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let codeReview = entry.codeReviewRemainingPercent {
                UsageBarRow(
                    title: self.localization.text("Code review", "コードレビュー"),
                    percentLeft: codeReview,
                    color: WidgetColors.color(for: self.entry.provider),
                    localization: self.localization)
            }
        }
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct SwitcherMediumUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 10) {
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let credits = entry.creditsRemaining {
                ValueLine(
                    title: self.localization.text("Credits", "クレジット"),
                    value: WidgetFormat.credits(credits, language: self.localization.language))
            }
            if let token = entry.tokenUsage {
                ValueLine(
                    title: self.localization.text("Today", "今日"),
                    value: WidgetFormat.costAndTokens(
                        cost: token.sessionCostUSD,
                        tokens: token.sessionTokens,
                        language: self.localization.language))
            }
        }
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct SwitcherLargeUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 12) {
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let codeReview = entry.codeReviewRemainingPercent {
                UsageBarRow(
                    title: self.localization.text("Code review", "コードレビュー"),
                    percentLeft: codeReview,
                    color: WidgetColors.color(for: self.entry.provider),
                    localization: self.localization)
            }
            if let credits = entry.creditsRemaining {
                ValueLine(
                    title: self.localization.text("Credits", "クレジット"),
                    value: WidgetFormat.credits(credits, language: self.localization.language))
            }
            if let token = entry.tokenUsage {
                VStack(alignment: .leading, spacing: 4) {
                    ValueLine(
                        title: self.localization.text("Today", "今日"),
                        value: WidgetFormat.costAndTokens(
                            cost: token.sessionCostUSD,
                            tokens: token.sessionTokens,
                            language: self.localization.language))
                    ValueLine(
                        title: self.localization.text("30d", "30日間"),
                        value: WidgetFormat.costAndTokens(
                            cost: token.last30DaysCostUSD,
                            tokens: token.last30DaysTokens,
                            language: self.localization.language))
                }
            }
            UsageHistoryChart(points: self.entry.dailyUsage, color: WidgetColors.color(for: self.entry.provider))
                .frame(height: 50)
        }
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct SmallUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 8) {
            HeaderView(provider: self.entry.provider, updatedAt: self.entry.updatedAt, localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let codeReview = entry.codeReviewRemainingPercent {
                UsageBarRow(
                    title: self.localization.text("Code review", "コードレビュー"),
                    percentLeft: codeReview,
                    color: WidgetColors.color(for: self.entry.provider),
                    localization: self.localization)
            }
        }
        .padding(12)
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct MediumUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 10) {
            HeaderView(provider: self.entry.provider, updatedAt: self.entry.updatedAt, localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let credits = entry.creditsRemaining {
                ValueLine(
                    title: self.localization.text("Credits", "クレジット"),
                    value: WidgetFormat.credits(credits, language: self.localization.language))
            }
            if let token = entry.tokenUsage {
                ValueLine(
                    title: self.localization.text("Today", "今日"),
                    value: WidgetFormat.costAndTokens(
                        cost: token.sessionCostUSD,
                        tokens: token.sessionTokens,
                        language: self.localization.language))
            }
        }
        .padding(12)
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct LargeUsageView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let localization: WidgetLocalization

    var body: some View {
        let metadata = ProviderDefaults.metadata[self.entry.provider]
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(provider: self.entry.provider, updatedAt: self.entry.updatedAt, localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.sessionLabel,
                    fallback: self.localization.text("Session", "セッション")),
                percentLeft: self.entry.primary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            UsageBarRow(
                title: self.localizedLabel(
                    metadata?.weeklyLabel,
                    fallback: self.localization.text("Weekly", "週間")),
                percentLeft: self.entry.secondary?.remainingPercent,
                color: WidgetColors.color(for: self.entry.provider),
                localization: self.localization)
            if let codeReview = entry.codeReviewRemainingPercent {
                UsageBarRow(
                    title: self.localization.text("Code review", "コードレビュー"),
                    percentLeft: codeReview,
                    color: WidgetColors.color(for: self.entry.provider),
                    localization: self.localization)
            }
            if let credits = entry.creditsRemaining {
                ValueLine(
                    title: self.localization.text("Credits", "クレジット"),
                    value: WidgetFormat.credits(credits, language: self.localization.language))
            }
            if let token = entry.tokenUsage {
                VStack(alignment: .leading, spacing: 4) {
                    ValueLine(
                        title: self.localization.text("Today", "今日"),
                        value: WidgetFormat.costAndTokens(
                            cost: token.sessionCostUSD,
                            tokens: token.sessionTokens,
                            language: self.localization.language))
                    ValueLine(
                        title: self.localization.text("30d", "30日間"),
                        value: WidgetFormat.costAndTokens(
                            cost: token.last30DaysCostUSD,
                            tokens: token.last30DaysTokens,
                            language: self.localization.language))
                }
            }
            UsageHistoryChart(points: self.entry.dailyUsage, color: WidgetColors.color(for: self.entry.provider))
                .frame(height: 50)
        }
        .padding(12)
    }

    private func localizedLabel(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        return self.localization.external.localizedProviderLabel(value)
    }
}

private struct HistoryView: View {
    let entry: WidgetSnapshot.ProviderEntry
    let isLarge: Bool
    let localization: WidgetLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(provider: self.entry.provider, updatedAt: self.entry.updatedAt, localization: self.localization)
            UsageHistoryChart(points: self.entry.dailyUsage, color: WidgetColors.color(for: self.entry.provider))
                .frame(height: self.isLarge ? 90 : 60)
            if let token = entry.tokenUsage {
                ValueLine(
                    title: self.localization.text("Today", "今日"),
                    value: WidgetFormat.costAndTokens(
                        cost: token.sessionCostUSD,
                        tokens: token.sessionTokens,
                        language: self.localization.language))
                ValueLine(
                    title: self.localization.text("30d", "30日間"),
                    value: WidgetFormat.costAndTokens(
                        cost: token.last30DaysCostUSD,
                        tokens: token.last30DaysTokens,
                        language: self.localization.language))
            }
        }
        .padding(12)
    }
}

private struct HeaderView: View {
    let provider: UsageProvider
    let updatedAt: Date
    let localization: WidgetLocalization

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(self.localization.external.providerName(self.provider))
                .font(.body)
                .fontWeight(.semibold)
            Spacer()
            Text(WidgetFormat.relativeDate(self.updatedAt, language: self.localization.language))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct UsageBarRow: View {
    let title: String
    let percentLeft: Double?
    let color: Color
    let localization: WidgetLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(self.title)
                    .font(.caption)
                Spacer()
                Text(WidgetFormat.percent(self.percentLeft, language: self.localization.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                let width = max(0, min(1, (percentLeft ?? 0) / 100)) * proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(self.color).frame(width: width)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct ValueLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(self.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(self.value)
                .font(.caption)
        }
    }
}

private struct UsageHistoryChart: View {
    let points: [WidgetSnapshot.DailyUsagePoint]
    let color: Color

    var body: some View {
        let values = self.points.map { point -> Double in
            if let cost = point.costUSD { return cost }
            return Double(point.totalTokens ?? 0)
        }
        let maxValue = values.max() ?? 0
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(values.indices, id: \.self) { index in
                let value = values[index]
                let height = maxValue > 0 ? CGFloat(value / maxValue) : 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(self.color.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: 1, y: height, anchor: .bottom)
                    .animation(.easeOut(duration: 0.2), value: height)
            }
        }
    }
}

enum WidgetColors {
    static func color(for provider: UsageProvider) -> Color {
        switch provider {
        case .codex, .codexOwner, .codexMember:
            Color(red: 73 / 255, green: 163 / 255, blue: 176 / 255)
        case .claude:
            Color(red: 204 / 255, green: 124 / 255, blue: 94 / 255)
        case .gemini:
            Color(red: 171 / 255, green: 135 / 255, blue: 234 / 255)
        case .antigravity:
            Color(red: 96 / 255, green: 186 / 255, blue: 126 / 255)
        case .cursor:
            Color(red: 0 / 255, green: 191 / 255, blue: 165 / 255) // #00BFA5 - Cursor teal
        case .zai:
            Color(red: 232 / 255, green: 90 / 255, blue: 106 / 255)
        case .factory:
            Color(red: 255 / 255, green: 107 / 255, blue: 53 / 255) // Factory orange
        }
    }
}

enum WidgetFormat {
    static func percent(_ value: Double?, language: AppLanguage) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f%%", value)
    }

    static func credits(_ value: Double, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    static func costAndTokens(cost: Double?, tokens: Int?, language: AppLanguage) -> String {
        let costText = cost.map { self.usd($0, language: language) } ?? "—"
        if let tokens {
            return "\(costText) · \(self.tokenCount(tokens, language: language))"
        }
        return costText
    }

    static func usd(_ value: Double, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    static func tokenCount(_ value: Int, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let raw = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let suffix = AppLocalization(language: language).choose("tokens", "トークン")
        return "\(raw) \(suffix)"
    }

    static func relativeDate(_ date: Date, language: AppLanguage) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = language.locale
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
