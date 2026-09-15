import SwiftUI

@main
struct TauberDefenceApp: App {
    var body: some Scene {
        WindowGroup {
            GameRootView()
                .preferredColorScheme(.dark)
        }
    }
}
