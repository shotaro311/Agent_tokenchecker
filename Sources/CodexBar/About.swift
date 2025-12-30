import AppKit
import CodexBarCore

@MainActor
func showAbout() {
    NSApp.activate(ignoringOtherApps: true)
    let language = AppLanguageStore.load()
    let l10n = AppLocalization(language: language)

    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let versionString = build.isEmpty ? version : "\(version) (\(build))"
    let buildTimestamp = Bundle.main.object(forInfoDictionaryKey: "CodexBuildTimestamp") as? String
    let gitCommit = Bundle.main.object(forInfoDictionaryKey: "CodexGitCommit") as? String

    let separator = NSAttributedString(string: " · ", attributes: [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
    ])

    func makeLink(_ title: String, urlString: String) -> NSAttributedString {
        NSAttributedString(string: title, attributes: [
            .link: URL(string: urlString) as Any,
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        ])
    }

    let credits = NSMutableAttributedString(string: l10n.choose(
        "Peter Steinberger — MIT License\n",
        "Peter Steinberger — MITライセンス\n"))
    credits.append(makeLink("GitHub", urlString: "https://github.com/steipete/CodexBar"))
    credits.append(separator)
    credits.append(makeLink(l10n.choose("Website", "ウェブサイト"), urlString: "https://steipete.me"))
    credits.append(separator)
    credits.append(makeLink(l10n.choose("Twitter", "Twitter"), urlString: "https://twitter.com/steipete"))
    credits.append(separator)
    credits.append(makeLink(l10n.choose("Email", "メール"), urlString: "mailto:peter@steipete.me"))
    if let buildTimestamp, let formatted = formattedBuildTimestamp(buildTimestamp, language: language) {
        var builtLine = l10n.choose("Built \(formatted)", "ビルド \(formatted)")
        if let gitCommit, !gitCommit.isEmpty, gitCommit != "unknown" {
            builtLine += " (\(gitCommit)"
            #if DEBUG
            builtLine += l10n.choose(" DEBUG BUILD", " デバッグビルド")
            #endif
            builtLine += ")"
        }
        credits.append(NSAttributedString(string: "\n\(builtLine)", attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]))
    }

    let options: [NSApplication.AboutPanelOptionKey: Any] = [
        .applicationName: "CodexBar",
        .applicationVersion: versionString,
        .version: versionString,
        .credits: credits,
        .applicationIcon: (NSApplication.shared.applicationIconImage ?? NSImage()) as Any,
    ]

    NSApp.orderFrontStandardAboutPanel(options: options)

    // Remove the focus ring around the app icon in the standard About panel for a cleaner look.
    if let aboutPanel = NSApp.windows.first(where: { $0.className.contains("About") }) {
        removeFocusRings(in: aboutPanel.contentView)
    }
}

private func formattedBuildTimestamp(_ timestamp: String, language: AppLanguage) -> String? {
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime]
    guard let date = parser.date(from: timestamp) else { return timestamp }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = language.locale
    return formatter.string(from: date)
}

@MainActor
private func removeFocusRings(in view: NSView?) {
    guard let view else { return }
    if let imageView = view as? NSImageView {
        imageView.focusRingType = .none
    }
    for subview in view.subviews {
        removeFocusRings(in: subview)
    }
}
