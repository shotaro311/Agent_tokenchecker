import CodexBarCore

@MainActor
extension StatusItemController {
    func runAntigravityLoginFlow() async {
        self.loginPhase = .idle
        let l10n = AppLocalization(language: self.settings.appLanguage)
        self.presentLoginAlert(
            title: l10n.choose(
                "Antigravity login is managed in the app",
                "Antigravityのログインはアプリ側で管理されています"),
            message: l10n.choose(
                "Open Antigravity to sign in, then refresh CodexBar.",
                "Antigravityを開いてログインし、CodexBarを更新してください。"))
    }
}
