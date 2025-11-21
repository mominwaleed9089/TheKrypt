import SwiftUI

struct EnterRoomRootView: View {
    @Environment(\.serviceLocator) private var services
    @State private var hasUsername = false

    var body: some View {
        Group {
            if hasUsername {
                NavigationStack { UserSearchView() }
            } else {
                UsernameSetupView { hasUsername = true }
            }
        }
        .task {
            do {
                let uid = try await services.auth.ensureSignedIn()
                _ = try await services.users.currentAppUser(uid: uid)
                hasUsername = true
            } catch {
                hasUsername = false
            }
        }
    }
}

