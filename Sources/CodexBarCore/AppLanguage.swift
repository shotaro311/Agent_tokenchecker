import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case japanese = "ja"
    case english = "en"

    public var id: String { self.rawValue }

    public var localeIdentifier: String {
        switch self {
        case .japanese: "ja_JP"
        case .english: "en_US"
        }
    }

    public var locale: Locale { Locale(identifier: self.localeIdentifier) }

    public var displayName: String {
        switch self {
        case .japanese: "日本語"
        case .english: "English"
        }
    }
}

public struct AppLocalization: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language
    }

    public var locale: Locale { self.language.locale }

    public func choose(_ english: String, _ japanese: String) -> String {
        switch self.language {
        case .english: english
        case .japanese: japanese
        }
    }

    public func format(_ english: String, _ japanese: String, _ args: CVarArg...) -> String {
        let template = self.choose(english, japanese)
        return String(format: template, locale: self.locale, arguments: args)
    }
}

public enum AppLanguageStore {
    private static let key = "appLanguage"

    public static func load(bundleID: String? = Bundle.main.bundleIdentifier) -> AppLanguage {
        guard let defaults = self.sharedDefaults(bundleID: bundleID) else { return .japanese }
        guard let raw = defaults.string(forKey: self.key),
              let language = AppLanguage(rawValue: raw)
        else {
            return .japanese
        }
        return language
    }

    public static func save(_ language: AppLanguage, bundleID: String? = Bundle.main.bundleIdentifier) {
        guard let defaults = self.sharedDefaults(bundleID: bundleID) else { return }
        defaults.set(language.rawValue, forKey: self.key)
    }

    private static func sharedDefaults(bundleID: String?) -> UserDefaults? {
        guard let groupID = WidgetSnapshotStore.appGroupID(for: bundleID) else {
            return UserDefaults.standard
        }
        return UserDefaults(suiteName: groupID) ?? UserDefaults.standard
    }
}
