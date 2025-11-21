import Foundation

// MARK: - XOR + Base64 (your original approach)

private func getKeyDigits(_ key: Int) -> [Int] {
    return String(key).compactMap { Int(String($0)) }
}

private func xorCipher(_ message: String, _ keyDigits: [Int]) -> String {
    var result = ""
    let chars = Array(message)
    for (i, c) in chars.enumerated() {
        guard let ascii = c.asciiValue else {
            result.append(c) // passthrough non-ascii
            continue
        }
        let digit = UInt8(keyDigits[i % keyDigits.count])
        let xorValue = ascii ^ digit
        result.append(Character(UnicodeScalar(xorValue)))
    }
    return result
}

func encryptMessage(_ message: String, _ key: Int) -> String {
    let keyDigits = getKeyDigits(key)
    let encrypted = xorCipher(message, keyDigits)
    let data = encrypted.data(using: .utf8) ?? Data()
    return data.base64EncodedString()
}

import Foundation

private func normalizeBase64(_ s: String) -> String {
    // Trim whitespace/newlines and support URL-safe Base64 variants.
    var cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
        .replacingOccurrences(of: " ", with: "")

    // URL-safe → standard
    cleaned = cleaned.replacingOccurrences(of: "-", with: "+")
                     .replacingOccurrences(of: "_", with: "/")

    // Pad to a length multiple of 4 with "="
    let rem = cleaned.count % 4
    if rem != 0 {
        cleaned.append(String(repeating: "=", count: 4 - rem))
    }
    return cleaned
}

func decryptMessage(_ encodedMessage: String, _ key: Int) -> String? {
    let normalized = normalizeBase64(encodedMessage)
    guard let data = Data(base64Encoded: normalized),
          let decoded = String(data: data, encoding: .utf8) else {
        return nil
    }
    let keyDigits = getKeyDigits(key)
    return xorCipher(decoded, keyDigits)
}


// MARK: - Multi-Shift (Vigenère-style with numeric list)

private func letterToNum(_ c: Character) -> Int {
    guard let scalar = String(c).uppercased().unicodeScalars.first else { return 0 }
    return Int(scalar.value) - Int(UnicodeScalar("A").value) + 1 // 1…26
}

private func numToLetter(_ n: Int) -> Character {
    Character(UnicodeScalar((n - 1) + Int(UnicodeScalar("A").value))!)
}

func encrypt2(_ message: String, _ key: [Int]) -> String {
    var out = ""
    let chars = Array(message)
    for (i, c) in chars.enumerated() {
        if c.isLetter {
            let val = letterToNum(c)
            var shifted = (val + key[i % key.count]) % 26
            if shifted == 0 { shifted = 26 }
            var enc = numToLetter(shifted)
            if c.isLowercase { enc = Character(enc.lowercased()) }
            out.append(enc)
        } else {
            out.append(c)
        }
    }
    return out
}

func decrypt2(_ message: String, _ key: [Int]) -> String {
    var out = ""
    let chars = Array(message)
    for (i, c) in chars.enumerated() {
        if c.isLetter {
            let val = letterToNum(c)
            var shifted = (val - key[i % key.count]) % 26
            if shifted <= 0 { shifted += 26 }
            var dec = numToLetter(shifted)
            if c.isLowercase { dec = Character(dec.lowercased()) }
            out.append(dec)
        } else {
            out.append(c)
        }
    }
    return out
}
