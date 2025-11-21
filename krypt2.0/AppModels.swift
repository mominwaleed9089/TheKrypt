import SwiftUI

enum OutputFormat: String, CaseIterable, Identifiable {
    case base64 = "Base64"
    case hex = "Hex"
    case pretty = "Pretty"
    var id: String { rawValue }
}

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    let date: Date
    let mode: String
    let action: String   // "Encrypt" or "Decrypt"
    let keyHint: String  // short preview (e.g., first 6 chars)
    let inputPreview: String
    let outputPreview: String
}

extension String {
    func toHexData() -> Data? {
        let s = trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count % 2 == 0 else { return nil }
        var data = Data(capacity: s.count/2)
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            guard next <= s.endIndex else { return nil }
            let byteStr = s[idx..<next]
            if let b = UInt8(byteStr, radix: 16) {
                data.append(b)
            } else { return nil }
            idx = next
        }
        return data
    }
}

extension Data {
    func toHex() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
