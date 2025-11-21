import SwiftUI

struct HowToView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("How to Use")
                    .font(.title)
                    .bold()

                Group {
                    Text("Secure Mode (ChaCha20-Poly1305)")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 10) {
                        step("Switch Mode to **Secure**.")
                        step("Set a key: Tap **Generate Key** or paste your **32-byte Base64** key. (Optional: **Save/Load Key** to/from Keychain.)")
                        step("Type your text in **Message**.")
                        step("Tap **Encrypt** → you’ll get a **Base64 blob** in **Output**.")
                        step("To decrypt, paste the blob into **Message** (or leave it in **Output**) and tap **Decrypt** with the **same key**.")
                        tip("If you see “Secure decrypt error”, the key doesn’t match or the blob is corrupted.")
                    }
                }

                Divider().opacity(0.3)

                Group {
                    Text("XOR (Educational)")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 10) {
                        step("Switch Mode to **XOR**.")
                        step("Enter a **single integer** key (e.g., `357`).")
                        step("Type your text in **Message**, then tap **Encrypt** → you’ll get **Base64** in **Output**.")
                        step("To decrypt, paste that Base64 into **Message** (or leave it in **Output**) and tap **Decrypt** using the **same integer key**.")
                        tip("If you see “doesn’t look like XOR ciphertext”, make sure you pasted the **Base64 output** produced by XOR Encrypt.")
                    }
                }

                Divider().opacity(0.3)

                Group {
                    Text("General Tips")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 10) {
                        bullet("**Copy Output** copies exactly what’s shown in Output.")
                        bullet("**Paste → Message** quickly grabs the clipboard into the Message box.")
                        bullet("Keyboard: tap the background or scroll to **dismiss**.")
                        bullet("We **clear Message after Encrypt** to avoid accidentally decrypting leftover plaintext.")
                        bullet("Switching modes **clears Message/Output** (keys are remembered per mode).")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("How to Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tiny helpers
    @ViewBuilder private func step(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").bold()
            Text(.init(text))
        }
    }

    @ViewBuilder private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Tip:")
                .font(.subheadline).bold()
            Text(.init(text))
                .font(.subheadline)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    @ViewBuilder private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("–")
            Text(.init(text))
        }
    }
}
