//import SwiftUI
//
//struct ServiceLocator {
//    let auth: AuthProviding
//    let users: UserProviding
//    let rooms: RoomProviding
//
//    static let offline = ServiceLocator(
//        auth: OfflineAuthService(),
//        users: OfflineUserService(),
//        rooms: OfflineRoomService()
//    )
//}
//
//private struct ServiceLocatorKey: EnvironmentKey {
//    static let defaultValue: ServiceLocator = .offline
//}
//
//extension EnvironmentValues {
//    var serviceLocator: ServiceLocator {
//        get { self[ServiceLocatorKey.self] }
//        set { self[ServiceLocatorKey.self] = newValue }
//    }
//}
