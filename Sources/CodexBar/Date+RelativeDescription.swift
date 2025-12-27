import CodexBarCore
import Foundation

enum RelativeTimeFormatters {
    @MainActor
    static func full(language: AppLanguage) -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = language.locale
        return formatter
    }
}

extension Date {
    @MainActor
    func relativeDescription(now: Date = .now, language: AppLanguage = .english) -> String {
        let seconds = abs(now.timeIntervalSince(self))
        if seconds < 15 {
            let l10n = AppLocalization(language: language)
            return l10n.choose("just now", "たった今")
        }
        return RelativeTimeFormatters.full(language: language).localizedString(for: self, relativeTo: now)
    }
}
