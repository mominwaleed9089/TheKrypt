import Foundation
import CryptoKit

enum SecureCryptoError: Error {
    case invalidKey
    case invalidBlob
}

struct SecureBox {
    let key: SymmetricKey

    // 👇 This init matches your KryptWorkspaceView calls
    init(base64Key: String) throws {
        guard let raw = Data(base64Encoded: base64Key), raw.count == 32 else {
            throw SecureCryptoError.invalidKey
        }
        self.key = SymmetricKey(data: raw)
    }

    static func generateBase64Key() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    // wire format: nonce(12) || ciphertext || tag(16)  → Base64
    func seal(_ plaintext: Data, aad: Data? = nil) throws -> String {
        var nonceBytes = [UInt8](repeating: 0, count: 12)
        let status = SecRandomCopyBytes(kSecRandomDefault, nonceBytes.count, &nonceBytes)
        precondition(status == errSecSuccess, "Secure random generation failed")
        let nonce = try ChaChaPoly.Nonce(data: Data(nonceBytes))

        let sealed: ChaChaPoly.SealedBox
        if let aad {
            sealed = try ChaChaPoly.seal(plaintext, using: key, nonce: nonce, authenticating: aad)
        } else {
            sealed = try ChaChaPoly.seal(plaintext, using: key, nonce: nonce)
        }

        let blob = Data(nonceBytes) + sealed.ciphertext + sealed.tag
        return blob.base64EncodedString()
    }

    func open(_ base64Blob: String, aad: Data? = nil) throws -> Data {
        guard let blob = Data(base64Encoded: base64Blob), blob.count >= 12 + 16 else {
            throw SecureCryptoError.invalidBlob
        }
        let nonceData = blob.prefix(12)
        let tag = blob.suffix(16)
        let ciphertext = blob.dropFirst(12).dropLast(16)

        let nonce = try ChaChaPoly.Nonce(data: nonceData)
        let sealed = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        if let aad { return try ChaChaPoly.open(sealed, using: key, authenticating: aad) }
        return try ChaChaPoly.open(sealed, using: key)
    }
}

// tiny helper
extension Data {
    static func +(lhs: Data, rhs: Data) -> Data {
        var m = Data(capacity: lhs.count + rhs.count)
        m.append(lhs); m.append(rhs); return m
    }
}
