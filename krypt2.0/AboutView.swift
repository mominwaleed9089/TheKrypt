import SwiftUI
import UIKit

struct AboutView: View {
    // Privacy Policy link
    private let privacyURL = URL(string: "https://www.apple.com/legal/privacy/data/en/messages/")!

    // Computed Support URL with template
    private var supportURL: URL {
        let device = UIDevice.current.model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let ios = UIDevice.current.systemVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let body = """
        \n\n---\nDevice: \(device)\niOS Version: \(ios)\nApp Version: \(appVersion)\nIssue:
        """
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded = "Krypt Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        return URL(string: "mailto:mominwaleed9089@gmail.com?subject=\(subjectEncoded)&body=\(bodyEncoded)")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("About Krypt")
                    .font(.system(.title, design: .rounded).weight(.bold))

                Text("""
Krypt is a personal text encryption tool designed for both secure communication and educational exploration of classical ciphers.

**Secure Mode** uses Apple’s CryptoKit (ChaCha20-Poly1305) to protect your text with modern, authenticated encryption.

**Educational Modes** (XOR) are included for learning purposes only and are **not secure** for protecting sensitive data.
""")

                Divider().opacity(0.25)

                Text("Encryption & Compliance")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                Text("""
- Uses Apple CryptoKit only (standard encryption APIs).
- Strong encryption is local to your device; you supply the key.
- Complies with U.S. EAR 740.17(b)(2) mass-market exemption.
- You are responsible for following local encryption laws.
""")

                Divider().opacity(0.25)

                Text("Disclaimer")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                Text("""
This app is provided for personal and educational purposes only. Do not use it to conceal or facilitate illegal activity. No guarantees are made regarding the strength of encryption or data security.
""")

                Divider().opacity(0.25)

                // Links
                VStack(alignment: .leading, spacing: 12) {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                            .font(.system(.headline, design: .rounded))
                    }
                    Link(destination: supportURL) {
                        Label("Contact Support", systemImage: "envelope")
                            .font(.system(.headline, design: .rounded))
                    }
                }

                Spacer(minLength: 8)

                Text("© \(String(Calendar.current.component(.year, from: Date()))) Krypt. All rights reserved.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
