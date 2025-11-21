import Foundation

enum AppConfig {
    // Set true to run fully local (no Firebase, no network)
    static let offlineDemo = true  // ← flip to false when you’re ready for server

    // Optional banner text for the UI
    static let offlineBanner = "Offline demo mode — no server connection."
}
