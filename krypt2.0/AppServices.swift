// AppServices.swift

import SwiftUI

protocol AuthProviding {
    func ensureSignedIn() async throws -> String
}

protocol UserProviding {
    func setUsername(uid: String, raw: String) async throws
    func searchUsers(prefix: String, limit: Int) async throws -> [AppUser]
    func currentAppUser(uid: String) async throws -> AppUser
}

protocol RoomProviding {
    func ensureRoom(uid: String, peerUid: String) async throws -> String
}

protocol ChatProviding: ObservableObject {
    var items: [ChatItem] { get set }
    var inputText: String { get set }

    func listen(roomId: String, xorPass: String)
    func stop()
    func send(roomId: String, text: String, xorPass: String) async throws
}

struct ServiceLocator {
    let auth: AuthProviding
    let users: UserProviding
    let rooms: RoomProviding

    static let offline = ServiceLocator(
        auth: OfflineAuthService(),
        users: OfflineUserService(),
        rooms: OfflineRoomService()
    )
}

private struct ServiceLocatorKey: EnvironmentKey {
    static let defaultValue: ServiceLocator = .offline
}

extension EnvironmentValues {
    var serviceLocator: ServiceLocator {
        get { self[ServiceLocatorKey.self] }
        set { self[ServiceLocatorKey.self] = newValue }
    }
}
