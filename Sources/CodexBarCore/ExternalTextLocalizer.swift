import Foundation

public struct ExternalTextLocalizer {
    public let language: AppLanguage
    private let l10n: AppLocalization

    public init(language: AppLanguage) {
        self.language = language
        self.l10n = AppLocalization(language: language)
    }

    public func providerName(_ provider: UsageProvider) -> String {
        ProviderDefaults.metadata[provider]?.displayName ?? provider.rawValue.capitalized
    }

    public func providerShortName(_ provider: UsageProvider) -> String {
        switch provider {
        case .codex:
            return "Codex"
        case .claude:
            return "Claude"
        case .gemini:
            return "Gemini"
        case .antigravity:
            return self.l10n.choose("Anti", "アンチ")
        case .cursor:
            return "Cursor"
        case .zai:
            return "z.ai"
        case .factory:
            return "Droid"
        }
    }

    public func providerToggleTitle(_ provider: UsageProvider) -> String {
        let name = self.providerName(provider)
        return self.l10n.choose("Show \(name) usage", "\(name)の使用量を表示")
    }

    public func localizedProviderLabel(_ label: String) -> String {
        guard self.language == .japanese else { return label }

        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized.lowercased() {
        case "session":
            return "セッション"
        case "weekly":
            return "週間"
        case "tokens":
            return "トークン"
        case "mcp":
            return "MCP"
        case "plan":
            return "プラン"
        case "on-demand", "on demand":
            return "オンデマンド"
        case "pro":
            return "プロ"
        case "flash":
            return "フラッシュ"
        case "standard":
            return "スタンダード"
        case "premium":
            return "プレミアム"
        case "sonnet":
            return "Sonnet"
        case "claude":
            return "Claude"
        case "gemini pro":
            return "Gemini Pro"
        case "gemini flash":
            return "Gemini Flash"
        default:
            return label
        }
    }

    public func localizedPlanName(_ text: String) -> String {
        guard self.language == .japanese else { return text }
        return self.applyReplacements(
            text,
            replacements: [
                (#"\bFree\b"#, "無料"),
                (#"\bPlus\b"#, "プラス"),
                (#"\bPro\b"#, "プロ"),
                (#"\bTeam\b"#, "チーム"),
                (#"\bEnterprise\b"#, "エンタープライズ"),
                (#"\bBusiness\b"#, "ビジネス"),
                (#"\bStarter\b"#, "スターター"),
                (#"\bStandard\b"#, "スタンダード"),
                (#"\bPremium\b"#, "プレミアム"),
                (#"\bDeveloper\b"#, "開発者"),
                (#"\bStudent\b"#, "学生"),
                (#"\bTrial\b"#, "トライアル"),
                (#"\bBasic\b"#, "ベーシック"),
                (#"\bUnlimited\b"#, "無制限"),
        ])
    }

    public func localizedStatusDescription(_ text: String) -> String {
        guard self.language == .japanese else { return text }
        return self.applyReplacements(
            text,
            replacements: [
                (#"All Systems Operational"#, "すべて正常稼働"),
                (#"\bOperational\b"#, "正常稼働"),
                (#"\bDegraded Performance\b"#, "性能低下"),
                (#"\bPartial Outage\b"#, "一部障害"),
                (#"\bMajor Outage\b"#, "大規模障害"),
                (#"\bUnder Maintenance\b"#, "メンテナンス中"),
                (#"\bMaintenance\b"#, "メンテナンス"),
                (#"\bIncident\b"#, "障害"),
                (#"\bInvestigating\b"#, "調査中"),
                (#"\bIdentified\b"#, "原因特定"),
                (#"\bMonitoring\b"#, "監視中"),
                (#"\bResolved\b"#, "解決済み"),
        ])
    }

    public func localizedErrorMessage(_ text: String) -> String {
        guard self.language == .japanese else { return text }
        let exact = self.applyReplacements(
            text,
            replacements: [
                (#"No Codex sessions found yet\. Run at least one Codex prompt first\."#,
                 "Codexのセッションがまだありません。まずCodexで1回実行してください。"),
                (#"Found sessions, but no rate limit events yet\."#,
                 "セッションは見つかりましたが、レート制限イベントがまだありません。"),
                (#"Could not parse Codex session log\."#,
                 "Codexのセッションログを解析できませんでした。"),
            ])
        return self.applyReplacements(
            exact,
            replacements: [
                (#"\bnot logged in\b"#, "ログインしていません"),
                (#"\bnot logged-in\b"#, "ログインしていません"),
                (#"\bnot installed\b"#, "インストールされていません"),
                (#"\bmissing\b"#, "不足しています"),
                (#"\binvalid\b"#, "無効"),
                (#"\bfailed\b"#, "失敗"),
                (#"\btimeout\b"#, "タイムアウト"),
                (#"\btimed out\b"#, "タイムアウトしました"),
                (#"\bnot found\b"#, "見つかりません"),
                (#"\bpermission denied\b"#, "権限がありません"),
                (#"\bunauthorized\b"#, "認証されていません"),
                (#"\bunavailable\b"#, "利用できません"),
                (#"\bnot running\b"#, "実行されていません"),
                (#"\bnetwork error\b"#, "ネットワークエラー"),
                (#"\bparse failed\b"#, "解析に失敗"),
                (#"\bcould not\b"#, "できませんでした"),
                (#"\bno data\b"#, "データがありません"),
            ])
    }

    private func applyReplacements(_ text: String, replacements: [(String, String)]) -> String {
        var output = text
        for (pattern, replacement) in replacements {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(output.startIndex..<output.endIndex, in: output)
            output = regex.stringByReplacingMatches(in: output, options: [], range: range, withTemplate: replacement)
        }
        return output
    }
}
