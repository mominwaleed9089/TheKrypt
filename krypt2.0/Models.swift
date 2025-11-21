import Foundation

// MARK: - Shared Models

struct AppUser: Identifiable, Equatable {
    let id: String
    let username: String
}

struct ChatItem: Identifiable, Equatable {
    let id: String
    let senderId: String
    let createdAt: Date
    let plaintext: String?
    let remaining: Int
}
