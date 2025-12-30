import Foundation

public enum UsageFormatter {
    public static func usageLine(
        remaining: Double,
        used: Double,
        language: AppLanguage = .english) -> String
    {
        _ = used
        let l10n = AppLocalization(language: language)
        let value = String(format: "%.0f%%", remaining)
        return l10n.choose("\(value) left", "残り\(value)")
    }

    public static func resetCountdownDescription(
        from date: Date,
        now: Date = .init(),
        language: AppLanguage = .english) -> String
    {
        let seconds = max(0, date.timeIntervalSince(now))
        if seconds < 1 {
            return language == .japanese ? "いま" : "now"
        }

        let totalMinutes = max(1, Int(ceil(seconds / 60.0)))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        if language == .japanese {
            if days > 0 {
                if hours > 0 { return "あと\(days)日\(hours)時間" }
                return "あと\(days)日"
            }
            if hours > 0 {
                if minutes > 0 { return "あと\(hours)時間\(minutes)分" }
                return "あと\(hours)時間"
            }
            return "あと\(totalMinutes)分"
        }

        if days > 0 {
            if hours > 0 { return "in \(days)d \(hours)h" }
            return "in \(days)d"
        }
        if hours > 0 {
            if minutes > 0 { return "in \(hours)h \(minutes)m" }
            return "in \(hours)h"
        }
        return "in \(totalMinutes)m"
    }

    public static func resetDescription(
        from date: Date,
        now: Date = .init(),
        language: AppLanguage = .english) -> String
    {
        // Human-friendly phrasing: today / tomorrow / date+time.
        let l10n = AppLocalization(language: language)
        let locale = l10n.locale
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow)
        {
            let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
            return l10n.choose("tomorrow, \(time)", "明日 \(time)")
        }
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale))
    }

    public static func updatedString(
        from date: Date,
        now: Date = .init(),
        language: AppLanguage = .english) -> String
    {
        let l10n = AppLocalization(language: language)
        let locale = l10n.locale
        let delta = now.timeIntervalSince(date)
        if abs(delta) < 60 {
            return l10n.choose("Updated just now", "更新: たった今")
        }
        if let hours = Calendar.current.dateComponents([.hour], from: date, to: now).hour, hours < 24 {
            #if os(macOS)
            let rel = RelativeDateTimeFormatter()
            rel.unitsStyle = .abbreviated
            rel.locale = locale
            let relative = rel.localizedString(for: date, relativeTo: now)
            return l10n.choose("Updated \(relative)", "更新: \(relative)")
            #else
            let seconds = max(0, Int(now.timeIntervalSince(date)))
            if seconds < 3600 {
                let minutes = max(1, seconds / 60)
                return l10n.choose("Updated \(minutes)m ago", "更新: \(minutes)分前")
            }
            let wholeHours = max(1, seconds / 3600)
            return l10n.choose("Updated \(wholeHours)h ago", "更新: \(wholeHours)時間前")
            #endif
        } else {
            let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
            return l10n.choose("Updated \(time)", "更新: \(time)")
        }
    }

    public static func creditsString(from value: Double, language: AppLanguage = .english) -> String {
        let l10n = AppLocalization(language: language)
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.maximumFractionDigits = 2
        number.locale = l10n.locale
        let formatted = number.string(from: NSNumber(value: value)) ?? String(Int(value))
        return l10n.choose("\(formatted) left", "残り\(formatted)")
    }

    public static func usdString(_ value: Double, language: AppLanguage = .english) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = language.locale
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    public static func currencyString(
        _ value: Double,
        currencyCode: String,
        language: AppLanguage = .english) -> String
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = language.locale
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencyCode) \(String(format: "%.2f", value))"
    }

    public static func tokenCountString(_ value: Int, language: AppLanguage = .english) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let units: [(threshold: Int, divisor: Double, suffix: String)] = [
            (1_000_000_000, 1_000_000_000, "B"),
            (1_000_000, 1_000_000, "M"),
            (1000, 1000, "K"),
        ]

        for unit in units where absValue >= unit.threshold {
            let scaled = Double(absValue) / unit.divisor
            let formatted: String
            if scaled >= 10 {
                formatted = String(format: "%.0f", scaled)
            } else {
                var s = String(format: "%.1f", scaled)
                if s.hasSuffix(".0") { s.removeLast(2) }
                formatted = s
            }
            return "\(sign)\(formatted)\(unit.suffix)"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.locale = language.locale
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public static func creditEventSummary(_ event: CreditEvent, language: AppLanguage = .english) -> String {
        let l10n = AppLocalization(language: language)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = l10n.locale
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.maximumFractionDigits = 2
        number.locale = l10n.locale
        let credits = number.string(from: NSNumber(value: event.creditsUsed)) ?? "0"
        let creditsLabel = l10n.choose("credits", "クレジット")
        return "\(formatter.string(from: event.date)) · \(event.service) · \(credits) \(creditsLabel)"
    }

    public static func creditEventCompact(_ event: CreditEvent, language: AppLanguage = .english) -> String {
        let l10n = AppLocalization(language: language)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = l10n.locale
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.maximumFractionDigits = 2
        number.locale = l10n.locale
        let credits = number.string(from: NSNumber(value: event.creditsUsed)) ?? "0"
        return "\(formatter.string(from: event.date)) — \(event.service): \(credits)"
    }

    public static func creditShort(_ value: Double) -> String {
        if value >= 1000 {
            let k = value / 1000
            return String(format: "%.1fk", k)
        }
        return String(format: "%.0f", value)
    }

    public static func truncatedSingleLine(_ text: String, max: Int = 80) -> String {
        let single = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard single.count > max else { return single }
        let idx = single.index(single.startIndex, offsetBy: max)
        return "\(single[..<idx])…"
    }

    public static func modelDisplayName(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return raw }

        let patterns = [
            #"(?:-|\s)\d{8}$"#,
            #"(?:-|\s)\d{4}-\d{2}-\d{2}$"#,
            #"\s\d{4}\s\d{4}$"#,
        ]

        for pattern in patterns {
            if let range = cleaned.range(of: pattern, options: .regularExpression) {
                cleaned.removeSubrange(range)
                break
            }
        }

        if let trailing = cleaned.range(of: #"[ \t-]+$"#, options: .regularExpression) {
            cleaned.removeSubrange(trailing)
        }

        return cleaned.isEmpty ? raw : cleaned
    }

    /// Cleans a provider plan string: strip ANSI/bracket noise, drop boilerplate words, collapse whitespace, and
    /// ensure a leading capital if the result starts lowercase.
    public static func cleanPlanName(_ text: String) -> String {
        let stripped = TextParsing.stripANSICodes(text)
        let withoutCodes = stripped.replacingOccurrences(
            of: #"^\s*(?:\[\d{1,3}m\s*)+"#,
            with: "",
            options: [.regularExpression])
        let withoutBoilerplate = withoutCodes.replacingOccurrences(
            of: #"(?i)\b(claude|codex|account|plan)\b"#,
            with: "",
            options: [.regularExpression])
        var cleaned = withoutBoilerplate
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            cleaned = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Capitalize first letter only if lowercase, preserving acronyms like "AI"
        if let first = cleaned.first, first.isLowercase {
            return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
        return cleaned
    }
}
