import CodexBarCore
import Foundation

enum UsagePaceText {
    private static let minimumExpectedPercent: Double = 3

    static func weekly(
        provider: UsageProvider,
        window: RateWindow,
        now: Date = .init(),
        language: AppLanguage = .english) -> String?
    {
        guard provider == .codex || provider == .claude else { return nil }
        guard window.remainingPercent > 0 else { return nil }
        guard let pace = UsagePace.weekly(window: window, now: now, defaultWindowMinutes: 10080) else { return nil }
        guard pace.expectedUsedPercent >= Self.minimumExpectedPercent else { return nil }

        let l10n = AppLocalization(language: language)
        let label = Self.label(for: pace.stage, language: language)
        let deltaSuffix = Self.deltaSuffix(for: pace)
        let etaSuffix = Self.etaSuffix(for: pace, now: now, language: language)

        if let etaSuffix {
            return l10n.choose(
                "Pace: \(label)\(deltaSuffix) · \(etaSuffix)",
                "ペース: \(label)\(deltaSuffix) · \(etaSuffix)")
        }
        return l10n.choose("Pace: \(label)\(deltaSuffix)", "ペース: \(label)\(deltaSuffix)")
    }

    private static func label(for stage: UsagePace.Stage, language: AppLanguage) -> String {
        switch stage {
        case .onTrack:
            return language == .japanese ? "順調" : "On pace"
        case .slightlyAhead, .ahead, .farAhead:
            return language == .japanese ? "上回り" : "Ahead"
        case .slightlyBehind, .behind, .farBehind:
            return language == .japanese ? "下回り" : "Behind"
        }
    }

    private static func deltaSuffix(for pace: UsagePace) -> String {
        let deltaValue = Int(abs(pace.deltaPercent).rounded())
        let sign = pace.deltaPercent >= 0 ? "+" : "-"
        return " (\(sign)\(deltaValue)%)"
    }

    private static func etaSuffix(for pace: UsagePace, now: Date, language: AppLanguage) -> String? {
        let l10n = AppLocalization(language: language)
        if pace.willLastToReset {
            return l10n.choose("Lasts to reset", "リセットまで持続")
        }
        guard let etaSeconds = pace.etaSeconds else { return nil }
        let etaText = Self.durationText(seconds: etaSeconds, now: now, language: language)
        if language == .japanese {
            if etaText == "いま" { return "今すぐ枯渇" }
            return "あと\(etaText)で枯渇"
        }
        if etaText == "now" { return "Runs out now" }
        return "Runs out in \(etaText)"
    }

    private static func durationText(seconds: TimeInterval, now: Date, language: AppLanguage) -> String {
        let date = now.addingTimeInterval(seconds)
        let countdown = UsageFormatter.resetCountdownDescription(from: date, now: now, language: language)
        if language == .japanese {
            if countdown == "いま" { return "いま" }
            if countdown.hasPrefix("あと") { return String(countdown.dropFirst(2)) }
            return countdown
        }
        if countdown == "now" { return "now" }
        if countdown.hasPrefix("in ") { return String(countdown.dropFirst(3)) }
        return countdown
    }
}
