import AppKit
import CodexBarCore
import SwiftUI

enum PreferencesTab: String, Hashable {
    case general
    case providers
    case advanced
    case about
    case debug

    static let windowWidth: CGFloat = 500
    static let windowHeight: CGFloat = 574

    var preferredHeight: CGFloat { PreferencesTab.windowHeight }
}

@MainActor
struct PreferencesView: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore
    let updater: UpdaterProviding
    @Bindable var selection: PreferencesSelection
    @State private var contentHeight: CGFloat = PreferencesTab.general.preferredHeight

    var body: some View {
        let l10n = AppLocalization(language: self.settings.appLanguage)
        TabView(selection: self.$selection.tab) {
            GeneralPane(settings: self.settings, store: self.store)
                .tabItem { Label(l10n.choose("General", "一般"), systemImage: "gearshape") }
                .tag(PreferencesTab.general)

            ProvidersPane(settings: self.settings, store: self.store)
                .tabItem { Label(l10n.choose("Providers", "プロバイダ"), systemImage: "square.grid.2x2") }
                .tag(PreferencesTab.providers)

            AdvancedPane(settings: self.settings)
                .tabItem { Label(l10n.choose("Advanced", "詳細"), systemImage: "slider.horizontal.3") }
                .tag(PreferencesTab.advanced)

            AboutPane(updater: self.updater, language: self.settings.appLanguage)
                .tabItem { Label(l10n.choose("About", "情報"), systemImage: "info.circle") }
                .tag(PreferencesTab.about)

            if self.settings.debugMenuEnabled {
                DebugPane(settings: self.settings, store: self.store)
                    .tabItem { Label(l10n.choose("Debug", "デバッグ"), systemImage: "ladybug") }
                    .tag(PreferencesTab.debug)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: PreferencesTab.windowWidth, height: self.contentHeight)
        .onAppear {
            self.updateHeight(for: self.selection.tab, animate: false)
            self.ensureValidTabSelection()
        }
        .onChange(of: self.selection.tab) { _, newValue in
            self.updateHeight(for: newValue, animate: true)
        }
        .onChange(of: self.settings.debugMenuEnabled) { _, _ in
            self.ensureValidTabSelection()
        }
    }

    private func updateHeight(for tab: PreferencesTab, animate: Bool) {
        let change = { self.contentHeight = tab.preferredHeight }
        if animate {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { change() }
        } else {
            change()
        }
    }

    private func ensureValidTabSelection() {
        if !self.settings.debugMenuEnabled, self.selection.tab == .debug {
            self.selection.tab = .general
            self.updateHeight(for: .general, animate: true)
        }
    }
}
