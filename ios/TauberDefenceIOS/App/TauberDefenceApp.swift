import SwiftUI

@main
struct TauberDefenceApp: App {
    @StateObject private var localization = AppLocalization()

    var body: some Scene {
        WindowGroup {
            GameRootView(localization: localization)
                .environmentObject(localization)
                .environment(\.locale, Locale(identifier: localization.effectiveLocale))
                .preferredColorScheme(.dark)
        }
    }
}
