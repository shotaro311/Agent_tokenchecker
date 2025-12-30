import CodexBarCore

@MainActor
extension StatusItemController {
    func runCodexLoginFlow(provider: UsageProvider) async {
        let env = self.settings.codexEnvironment(for: provider)
        let result = await CodexLoginRunner.run(timeout: 120, environment: env)
        guard !Task.isCancelled else { return }
        self.loginPhase = .idle
        self.presentCodexLoginResult(result)
        let outcome = self.describe(result.outcome)
        let length = result.output.count
        self.loginLogger.info("Codex login", metadata: ["outcome": outcome, "length": "\(length)"])
        print("[CodexBar] Codex login outcome=\(outcome) len=\(length)")
        if case .success = result.outcome {
            self.postLoginNotification(for: provider)
        }
    }
}
