import Foundation
import Combine
import SwiftUI

// MARK: - Offline Auth

final class OfflineAuthService: AuthProviding {
    func ensureSignedIn() async throws -> String {
        return "local-\(UUID().uuidString.prefix(8))"
    }
}

// MARK: - Offline Users

final class OfflineUserService: UserProviding {
    private var me: AppUser = .init(id: "me-local", username: "You")
    private var directory: [AppUser] = [
        .init(id: "peer-a", username: "Alice"),
        .init(id: "peer-b", username: "Bob"),
        .init(id: "peer-c", username: "Charlie"),
    ]

    func setUsername(uid: String, raw: String) async throws {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 3 else { throw NSError(domain: "username", code: 1) }
        me = .init(id: uid, username: name)
    }

    func searchUsers(prefix: String, limit: Int = 20) async throws -> [AppUser] {
        let p = prefix.lowercased()
        guard !p.isEmpty else { return [] }
        return directory
            .filter { $0.username.lowercased().hasPrefix(p) }
            .prefix(limit)
            .map { $0 }
    }

    func currentAppUser(uid: String) async throws -> AppUser {
        AppUser(id: uid, username: me.username)
    }
}

// MARK: - Offline Rooms

final class OfflineRoomService: RoomProviding {
    func ensureRoom(uid: String, peerUid: String) async throws -> String {
        let pair = [uid, peerUid].sorted().joined(separator: "|")
        return "room-\(pair.hashValue)"
    }
}

// MARK: - Offline Chat Service (in-memory)

final class OfflineChatService: ObservableObject, ChatProviding {
    @Published var items: [ChatItem] = []
    @Published var inputText: String = ""

    private var timers: [String: Timer] = [:]
    private var myUid: String = "me-local"

    init() { }

    func listen(roomId: String, xorPass: String) { }

    func stop() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    func send(roomId: String, text: String, xorPass: String) async throws {
        let id = UUID().uuidString
        let now = Date()
        let item = ChatItem(
            id: id,
            senderId: myUid,
            createdAt: now,
            plaintext: text,
            remaining: 60
        )

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {   // <<< animated insert
                self.items.append(item)
            }
            self.startCountdown(for: id, from: now)
        }
    }

    private func startCountdown(for id: String, from created: Date) {
        timers[id]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { return }

            DispatchQueue.main.async {
                guard let index = self.items.firstIndex(where: { $0.id == id }) else {
                    t.invalidate()
                    return
                }

                let elapsed = Int(Date().timeIntervalSince(created))
                let remaining = max(0, 60 - elapsed)

                var current = self.items[index]
                current = ChatItem(
                    id: current.id,
                    senderId: current.senderId,
                    createdAt: current.createdAt,
                    plaintext: current.plaintext,
                    remaining: remaining
                )
                self.items[index] = current

                if remaining == 0 {
                    t.invalidate()
                    self.timers[id] = nil
                    withAnimation(.easeInOut(duration: 0.3)) {   // <<< animated delete
                        self.items.removeAll { $0.id == id }
                    }
                }
            }
        }

        timers[id] = timer
    }
}
