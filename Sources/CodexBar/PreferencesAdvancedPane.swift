import AppKit
import CodexBarCore
import SwiftUI

@MainActor
struct AdvancedPane: View {
    @Bindable var settings: SettingsStore
    @State private var isInstallingCLI = false
    @State private var cliStatus: String?

    var body: some View {
        let l10n = AppLocalization(language: self.settings.appLanguage)
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 6) {
                    Text(l10n.choose("Refresh cadence", "更新間隔"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Picker("", selection: self.$settings.refreshFrequency) {
                        ForEach(RefreshFrequency.allCases) { option in
                            Text(option.label(language: self.settings.appLanguage)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if self.settings.refreshFrequency == .manual {
                        Text(l10n.choose(
                            "Auto-refresh is off; use the menu's Refresh command.",
                            "自動更新はオフです。メニューの「更新」を使用してください。"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(l10n.choose("Display", "表示"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: l10n.choose("Show usage as used", "使用量を使用済みで表示"),
                        subtitle: l10n.choose(
                            "Progress bars fill as you consume quota (instead of showing remaining).",
                            "進捗バーを使用量に応じて埋めます（残量表示ではありません）。"),
                        binding: self.$settings.usageBarsShowUsed)
                    PreferenceToggleRow(
                        title: l10n.choose("Show credits + extra usage", "クレジットと追加使用量を表示"),
                        subtitle: l10n.choose(
                            "Show Codex Credits and Claude Extra usage sections in the menu.",
                            "メニューにCodexクレジットとClaudeの追加使用量を表示します。"),
                        binding: self.$settings.showOptionalCreditsAndExtraUsage)
                    PreferenceToggleRow(
                        title: l10n.choose("Merge Icons", "アイコンを統合"),
                        subtitle: l10n.choose(
                            "Use a single menu bar icon with a provider switcher.",
                            "1つのメニューバーアイコンにまとめ、プロバイダ切替を表示します。"),
                        binding: self.$settings.mergeIcons)
                    PreferenceToggleRow(
                        title: l10n.choose("Switcher shows icons", "スイッチャーにアイコンを表示"),
                        subtitle: l10n.choose(
                            "Show provider icons in the switcher (otherwise show a weekly progress line).",
                            "スイッチャーにアイコンを表示します（非表示の場合は週間進捗を表示）。"),
                        binding: self.$settings.switcherShowsIcons)
                        .disabled(!self.settings.mergeIcons)
                        .opacity(self.settings.mergeIcons ? 1 : 0.5)
                    PreferenceToggleRow(
                        title: l10n.choose("Surprise me", "サプライズ"),
                        subtitle: l10n.choose(
                            "Check if you like your agents having some fun up there.",
                            "ちょっとした演出を有効にします。"),
                        binding: self.$settings.randomBlinkEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 10) {
                    HStack(spacing: 12) {
                        Button {
                            Task { await self.installCLI() }
                        } label: {
                            if self.isInstallingCLI {
                                ProgressView().controlSize(.small)
                            } else {
                                Text(l10n.choose("Install CLI", "CLIをインストール"))
                            }
                        }
                        .disabled(self.isInstallingCLI)

                        if let status = self.cliStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }
                    }
                    Text(l10n.choose(
                        "Symlink CodexBarCLI to /usr/local/bin and /opt/homebrew/bin as codexbar.",
                        "CodexBarCLIを /usr/local/bin と /opt/homebrew/bin に codexbar としてシンボリックリンクします。"))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                SettingsSection(contentSpacing: 10) {
                    PreferenceToggleRow(
                        title: l10n.choose("Show Debug Settings", "デバッグ設定を表示"),
                        subtitle: l10n.choose(
                            "Expose troubleshooting tools in the Debug tab.",
                            "デバッグタブにトラブルシューティング用ツールを表示します。"),
                        binding: self.$settings.debugMenuEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

extension AdvancedPane {
    private func installCLI() async {
        if self.isInstallingCLI { return }
        self.isInstallingCLI = true
        defer { self.isInstallingCLI = false }

        let l10n = AppLocalization(language: self.settings.appLanguage)
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/CodexBarCLI")
        let fm = FileManager.default
        guard fm.fileExists(atPath: helperURL.path) else {
            self.cliStatus = l10n.choose(
                "CodexBarCLI not found in app bundle.",
                "アプリ内にCodexBarCLIが見つかりません。")
            return
        }

        let destinations = [
            "/usr/local/bin/codexbar",
            "/opt/homebrew/bin/codexbar",
        ]

        var results: [String] = []
        for dest in destinations {
            let dir = (dest as NSString).deletingLastPathComponent
            guard fm.fileExists(atPath: dir) else { continue }
            guard fm.isWritableFile(atPath: dir) else {
                results.append(l10n.choose("No write access: \(dir)", "書き込み権限なし: \(dir)"))
                continue
            }

            if fm.fileExists(atPath: dest) {
                if Self.isLink(atPath: dest, pointingTo: helperURL.path) {
                    results.append(l10n.choose("Installed: \(dir)", "インストール済み: \(dir)"))
                } else {
                    results.append(l10n.choose("Exists: \(dir)", "既存: \(dir)"))
                }
                continue
            }

            do {
                try fm.createSymbolicLink(atPath: dest, withDestinationPath: helperURL.path)
                results.append(l10n.choose("Installed: \(dir)", "インストール済み: \(dir)"))
            } catch {
                results.append(l10n.choose("Failed: \(dir)", "失敗: \(dir)"))
            }
        }

        self.cliStatus = results.isEmpty
            ? l10n.choose("No writable bin dirs found.", "書き込み可能なbinディレクトリがありません。")
            : results.joined(separator: " · ")
    }

    private static func isLink(atPath path: String, pointingTo destination: String) -> Bool {
        guard let link = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else { return false }
        let dir = (path as NSString).deletingLastPathComponent
        let resolved = URL(fileURLWithPath: link, relativeTo: URL(fileURLWithPath: dir))
            .standardizedFileURL
            .path
        return resolved == destination
    }
}
