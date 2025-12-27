import AppKit
import CodexBarCore
import SwiftUI

@MainActor
struct AboutPane: View {
    let updater: UpdaterProviding
    let language: AppLanguage
    @State private var iconHover = false
    @AppStorage("autoUpdateEnabled") private var autoUpdateEnabled: Bool = true
    @State private var didLoadUpdaterState = false

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    private var buildTimestamp: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "CodexBuildTimestamp") as? String else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        guard let date = parser.date(from: raw) else { return raw }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = self.language.locale
        return formatter.string(from: date)
    }

    var body: some View {
        let l10n = AppLocalization(language: self.language)
        VStack(spacing: 12) {
            if let image = NSApplication.shared.applicationIconImage {
                Button(action: self.openProjectHome) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 92, height: 92)
                        .cornerRadius(16)
                        .scaleEffect(self.iconHover ? 1.05 : 1.0)
                        .shadow(color: self.iconHover ? .accentColor.opacity(0.25) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        self.iconHover = hovering
                    }
                }
            }

            VStack(spacing: 2) {
                Text("CodexBar")
                    .font(.title3).bold()
                Text(l10n.choose("Version \(self.versionString)", "バージョン \(self.versionString)"))
                    .foregroundStyle(.secondary)
                if let buildTimestamp {
                    Text(l10n.choose("Built \(buildTimestamp)", "ビルド \(buildTimestamp)"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(l10n.choose(
                    "May your tokens never run out—keep Codex limits in view.",
                    "トークン切れのないよう、Codexの上限を常に見えるところに。"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .center, spacing: 10) {
                AboutLinkRow(
                    icon: "chevron.left.slash.chevron.right",
                    title: "GitHub",
                    url: "https://github.com/steipete/CodexBar")
                AboutLinkRow(icon: "globe", title: l10n.choose("Website", "ウェブサイト"), url: "https://steipete.me")
                AboutLinkRow(icon: "bird", title: l10n.choose("Twitter", "Twitter"), url: "https://twitter.com/steipete")
                AboutLinkRow(icon: "envelope", title: l10n.choose("Email", "メール"), url: "mailto:peter@steipete.me")
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            Divider()

            if self.updater.isAvailable {
                VStack(spacing: 10) {
                    Toggle(l10n.choose("Check for updates automatically", "更新を自動的に確認"), isOn: self.$autoUpdateEnabled)
                        .toggleStyle(.checkbox)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Button(l10n.choose("Check for Updates…", "更新を確認…")) { self.updater.checkForUpdates(nil) }
                }
            } else {
                Text(self.updater.unavailableReason ?? l10n.choose(
                    "Updates unavailable in this build.",
                    "このビルドでは更新を利用できません。"))
                    .foregroundStyle(.secondary)
            }

            Text(l10n.choose(
                "© 2025 Peter Steinberger. MIT License.",
                "© 2025 Peter Steinberger. MITライセンス。"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onAppear {
            guard !self.didLoadUpdaterState else { return }
            // Align Sparkle's flag with the persisted preference on first load.
            self.updater.automaticallyChecksForUpdates = self.autoUpdateEnabled
            self.updater.automaticallyDownloadsUpdates = self.autoUpdateEnabled
            self.didLoadUpdaterState = true
        }
        .onChange(of: self.autoUpdateEnabled) { _, newValue in
            self.updater.automaticallyChecksForUpdates = newValue
            self.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    private func openProjectHome() {
        guard let url = URL(string: "https://github.com/steipete/CodexBar") else { return }
        NSWorkspace.shared.open(url)
    }
}
