

import Foundation

final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryEntry] = []
    private let key = "history.entries.v1"
    private let maxCount = 10

    init() {
        load()
    }

    func add(_ entry: HistoryEntry) {
        items.insert(entry, at: 0)
        if items.count > maxCount { items.removeLast(items.count - maxCount) }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
