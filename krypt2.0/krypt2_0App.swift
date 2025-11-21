import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct KryptApp: App {

    init() {
        // Same logic you had before, just formatted
        if AppConfig.offlineDemo == false {
            #if canImport(FirebaseCore)
            if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
                FirebaseApp.configure()
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.serviceLocator, ServiceLocator.offline)
        }
    }
}
