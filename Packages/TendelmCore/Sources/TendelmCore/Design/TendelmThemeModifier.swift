import SwiftUI
import UIKit

/// Root-level theme wiring. Applies sage as the process tint, paints
/// the view background in paper, hides SwiftUI's default scroll
/// background so `Form` / `List` inherit the paper surface, and
/// configures the nav bar + tab bar appearance once.
public struct TendelmThemeModifier: ViewModifier {

    @Environment(\.habitTheme) private var theme
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appPaletteTrait) private var paletteTrait

    public init() {}

    public func body(content: Content) -> some View {
        let _ = paletteTrait // Observe the native color-trait change without replacing views.
        content
            .tint(Color.kadoSage.inPalette(appTheme ?? theme))
            .background(PaletteTraitInstaller(theme: appTheme ?? theme))
            .background(Color.kadoBackground.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .onAppear(perform: Self.applyUIKitAppearance)
    }

    /// Configures `UINavigationBarAppearance` + `UITabBarAppearance`
    /// once per process. Called from `.onAppear` on the root view; the
    /// `static let` once-semantics make repeat calls free.
    private static let applyUIKitAppearance: () -> Void = {
        let once = ApplyOnce()
        return { once.run() }
    }()

    private final class ApplyOnce {
        private var didRun = false

        @MainActor
        func run() {
            guard !didRun else { return }
            didRun = true

            // iOS 26 owns Liquid Glass navigation and tab surfaces. Do not
            // replace them with legacy appearance objects or solid backgrounds.
            if #available(iOS 26.0, *) { return }

            // Keep the system's default nav bar material so the large
            // title stays visible and the bar blends naturally with the
            // paper content behind it. Only override typography: ink
            // foreground + Fraunces for the large title.
            let nav = UINavigationBarAppearance()
            nav.configureWithDefaultBackground()
            nav.titleTextAttributes = [
                .foregroundColor: UIColor(Color.kadoForeground),
                .font: UIFont(name: "Fraunces-Medium", size: 17)
                    ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            nav.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Color.kadoForeground),
                .font: UIFont(name: "Fraunces-Regular", size: 34)
                    ?? UIFont.systemFont(ofSize: 34, weight: .semibold)
            ]
            UINavigationBar.appearance().standardAppearance = nav
            UINavigationBar.appearance().scrollEdgeAppearance = nav
            UINavigationBar.appearance().compactAppearance = nav

            // Tab bar stays on the default blur too — ensures the
            // floating tab pill reads correctly over paper.
            let tab = UITabBarAppearance()
            tab.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tab
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
    }
}

public extension View {
    /// Apply Tendelm's theme at the root of the app — typically on
    /// `ContentView`'s body.
    func kadoTheme() -> some View { modifier(TendelmThemeModifier()) }
}
