import Sparkle
import SwiftUI

@main
struct Github_Actions_SandboxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Add "Check for Updates..." menu item to the app menu
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView()
            }
        }
    }
}
