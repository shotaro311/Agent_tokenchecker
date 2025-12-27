import Foundation

public enum ClaudeUsageDataSource: String, CaseIterable, Identifiable, Sendable {
    case oauth
    case web
    case cli

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .oauth: "OAuth API"
        case .web: "Web API (cookies)"
        case .cli: "CLI (PTY)"
        }
    }

    public func displayName(language: AppLanguage) -> String {
        switch self {
        case .oauth:
            return language == .japanese ? "OAuth API" : "OAuth API"
        case .web:
            return language == .japanese ? "Web API（Cookie）" : "Web API (cookies)"
        case .cli:
            return language == .japanese ? "CLI（PTY）" : "CLI (PTY)"
        }
    }
}
