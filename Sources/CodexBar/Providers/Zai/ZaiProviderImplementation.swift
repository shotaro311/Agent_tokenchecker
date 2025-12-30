import AppKit
import CodexBarCore
import Foundation

struct ZaiProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .zai
    let style: IconStyle = .zai

    func makeFetch(context: ProviderBuildContext) -> @Sendable () async throws -> UsageSnapshot {
        {
            let fromSettings = await MainActor.run {
                context.settings.zaiAPIToken.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let apiKey = !fromSettings.isEmpty ? fromSettings : ZaiSettingsReader.apiToken()
            guard let apiKey else {
                throw ZaiSettingsError.missingToken
            }
            let usage = try await ZaiUsageFetcher.fetchUsage(apiKey: apiKey)
            return usage.toUsageSnapshot()
        }
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        let l10n = context.localization
        return [
            ProviderSettingsFieldDescriptor(
                id: "zai-api-token",
                title: l10n.choose("API token", "APIトークン"),
                subtitle: l10n.choose(
                    "Stored in Keychain. Paste the token from the z.ai dashboard.",
                    "キーチェーンに保存されます。z.aiのダッシュボードでトークンを取得して貼り付けてください。"),
                kind: .secure,
                placeholder: l10n.choose("Paste token…", "トークンを貼り付け…"),
                binding: context.stringBinding(\.zaiAPIToken),
                actions: [],
                isVisible: nil),
        ]
    }
}
