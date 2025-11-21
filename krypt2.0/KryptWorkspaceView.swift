import SwiftUI
import UIKit

// MARK: - Typography helpers
extension Text {
    func kryptTitle() -> some View { self.font(.system(.title2, design: .rounded).weight(.bold)) }
    func kryptHeader() -> some View { self.font(.system(.headline, design: .rounded).weight(.semibold)) }
}
extension View {
    func kryptSectionHeader() -> some View {
        self.font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Banner (error/info)
enum BannerKind { case info, success, warning, error }
struct Banner: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var kind: BannerKind
}
struct BannerView: View {
    let banner: Banner
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(banner.text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
    private var icon: String {
        switch banner.kind {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }
    private var background: Color {
        switch banner.kind {
        case .info: Color.blue.opacity(0.15)
        case .success: Color.green.opacity(0.18)
        case .warning: Color.yellow.opacity(0.22)
        case .error: Color.red.opacity(0.22)
        }
    }
    private var foreground: Color {
        switch banner.kind {
        case .info: .blue
        case .success: .green
        case .warning: .yellow
        case .error: .red
        }
    }
}


struct HistoryView: View {
    @ObservedObject var history: HistoryStore
    var onReuse: (HistoryEntry) -> Void

    var body: some View {
        List {
            ForEach(history.items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.action).font(.subheadline.bold())
                        Text("· \(item.mode)").font(.subheadline)
                        Spacer()
                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Key: \(item.keyHint)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Output: \(item.outputPreview)")
                        .font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack {
                        Spacer()
                        Button("Reuse") { onReuse(item) }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Focus targets
enum KryptField: Hashable { case message, key, output }

struct KryptWorkspaceView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focus: KryptField?

    // Settings
    @AppStorage("autoClearAfterEncrypt") private var autoClearAfterEncrypt = true
    @AppStorage("autoCopyAfterEncrypt")  private var autoCopyAfterEncrypt  = false
    @AppStorage("autoLoadSecureKeyOnLaunch") private var autoLoadSecureKeyOnLaunch = true
    @AppStorage("outputFormat") private var outputFormatRaw: String = OutputFormat.base64.rawValue

    // Per-mode keys
    @State private var secureKey: String = ""
    @State private var xorKey: String = ""

    // IO
    @State private var mode: CipherMode = .secure
    @State private var message: String = ""
    @State private var output: String = ""

    // Feedback
    @State private var toast: String? = nil
    @State private var banner: Banner? = nil

    // History
    @StateObject private var historyStore = HistoryStore()

    // Top toolbar sheets
    @State private var showingSettings = false
    @State private var showingHistory = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                // Mode picker (Secure + XOR only)
                Picker("Mode", selection: $mode) {
                    Text("Secure").tag(CipherMode.secure)
                    Text("XOR (educational)").tag(CipherMode.xor)
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _, _ in
                    message = ""; output = ""; focus = nil
                    showToast("Mode changed → cleared fields")
                }

                if mode != .secure {
                    Label("Educational mode — not secure for real data.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(10)
                        .background(Color.yellow.opacity(scheme == .dark ? 0.25 : 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.primary)
                }

                // Message
                Group {
                    Text("Message").kryptHeader()

                    TextEditor(text: $message)
                        .focused($focus, equals: .message)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))

                    HStack(spacing: 8) {
                        Button {
                            if let s = UIPasteboard.general.string {
                                message = s
                                if mode == .xor, isLikelyBase64(s) {
                                    showToast("Looks like XOR ciphertext — press Decrypt")
                                } else if mode == .secure, isLikelyBase64(s) {
                                    showToast("Looks like Secure blob — press Decrypt")
                                } else {
                                    showToast("Pasted into Message")
                                }
                                focus = nil
                            } else {
                                showToast("Clipboard is empty")
                            }
                        } label: {
                            Label("Paste → Message", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }

                // Keys UI (per-mode)
                if mode == .secure {
                    SecureKeySection(
                        keyInput: $secureKey,
                        toast: { showToast($0) },
                        strengthOK: isValid32ByteBase64(secureKey),
                        focus: $focus
                    )
                } else if mode == .xor {
                    ToyKeySection(mode: .xor, keyInput: $xorKey, focus: $focus)
                }

                // Output format picker (Base64 / Hex only)
                Picker("Output Format", selection: $outputFormatRaw) {
                    Text("Base64").tag(OutputFormat.base64.rawValue)
                    Text("Hex").tag(OutputFormat.hex.rawValue)
                }
                .pickerStyle(.segmented)

                // Actions
                HStack(spacing: 12) {
                    Button(action: encrypt) {
                        Label("Encrypt", systemImage: "lock.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)

                    Button(action: decrypt) {
                        Label("Decrypt", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                .controlSize(.large)

                // Output
                Group {
                    HStack {
                        Text("Output").kryptHeader()
                        Spacer()
                        Button {
                            UIPasteboard.general.string = output
                            showToast("Copied Output")
                            focus = nil
                        } label: {
                            Label("Copy Output", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                    TextEditor(text: $output)
                        .focused($focus, equals: .output)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
                }

                Text(
                    mode == .secure
                    ? "Secure mode uses AEAD (ChaCha20-Poly1305) with per-message nonces and integrity."
                    : "Tip: Use the same mode & key to decrypt what you’ve encrypted."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            .padding()
        }
        // Auto-dismiss keyboard
        .modifier(ScrollDismissModifier(focus: $focus))
        .onTapGesture { focus = nil }

        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient.ignoresSafeArea())

        // Top toolbar: Settings + History icons on the right
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock")
                }

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                HistoryView(history: historyStore) { entry in
                    message = entry.outputPreview
                    showToast("Loaded from history → Message")
                    focus = .message
                }
            }
        }

        // 🔺 Top banner
        .overlay(alignment: .top) {
            if let b = banner {
                BannerView(banner: b)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
            }
        }
        // 🔻 Bottom toast
        .overlay(alignment: .bottom) {
            if let t = toast {
                Text(t)
                    .font(.system(.subheadline, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        // Paste detection toast
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            if UIPasteboard.general.hasStrings,
               let s = UIPasteboard.general.string,
               !s.isEmpty {
                showToast("Clipboard detected — tap “Paste → Message” to use")
            }
        }
        // Auto-load secure key if desired
        .onAppear {
            if autoLoadSecureKeyOnLaunch,
               secureKey.isEmpty,
               let k = KeychainHelper.loadKey() {
                secureKey = k
                showToast("Loaded secure key from Keychain")
            }
        }
        .dynamicTypeSize(.small ... .accessibility3)
    }

    // MARK: - UI helpers
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Krypt Console").kryptTitle().foregroundStyle(.primary)
            Text("Choose a mode, provide a key, then encrypt or decrypt.")
                .foregroundStyle(.secondary)
        }.padding(.bottom, 8)
    }

    private var backgroundGradient: LinearGradient {
        if scheme == .dark {
            LinearGradient(
                colors: [.black, Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { toast = nil }
        }
    }
    private func showError(_ message: String) { showBanner(message, kind: .error) }
    private func showBanner(_ message: String, kind: BannerKind = .info) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            banner = Banner(text: message, kind: kind)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut) {
                if banner?.text == message { banner = nil }
            }
        }
    }

    private func isLikelyBase64(_ s: String) -> Bool {
        let cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard cleaned.count >= 4 else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        return cleaned.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private func isValid32ByteBase64(_ s: String) -> Bool {
        guard let d = Data(base64Encoded: s.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return d.count == 32
    }

    private var outputFormat: OutputFormat {
        OutputFormat(rawValue: outputFormatRaw) ?? .base64
    }

    private func formatOutput(data: Data, base64Fallback: String) -> String {
        switch outputFormat {
        case .base64:
            return base64Fallback
        case .hex:
            return data.toHex()
        case .pretty:
            // Unreachable with current UI (no Pretty picker),
            // kept for compatibility if OutputFormat still includes it.
            let s = base64Fallback
            var lines: [String] = []
            var i = s.startIndex
            while i < s.endIndex {
                let j = s.index(i, offsetBy: 64, limitedBy: s.endIndex) ?? s.endIndex
                lines.append(String(s[i..<j]))
                i = j
            }
            return lines.joined(separator: "\n")
        }
    }

    // MARK: - Actions
    private func encrypt() {
        switch mode {
        case .secure:
            do {
                let key = secureKey.trimmingCharacters(in: .whitespacesAndNewlines)
                let box = try SecureBox(base64Key: key)
                let pt = Data(message.utf8)
                let blob = try box.seal(pt)
                let raw = Data(base64Encoded: blob) ?? Data()
                output = formatOutput(data: raw, base64Fallback: blob)
                if autoCopyAfterEncrypt { UIPasteboard.general.string = output }
                if autoClearAfterEncrypt { message = "" }
                addHistory(action: "Encrypt")
            } catch {
                showError("Secure encrypt error: key must be a 32-byte Base64 value.")
            }

        case .xor:
            guard let intKey = Int(xorKey.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                showError("Invalid XOR key. Enter a single integer (e.g. 357)."); return
            }
            let b64 = encryptMessage(message, intKey)
            let raw = Data(base64Encoded: b64) ?? Data()
            output = formatOutput(data: raw, base64Fallback: b64)
            if autoCopyAfterEncrypt { UIPasteboard.general.string = output }
            if autoClearAfterEncrypt { message = "" }
            addHistory(action: "Encrypt")
        }
    }

    private func decrypt() {
        let candidateInput = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? output : message

        switch mode {
        case .secure:
            guard isLikelyBase64(candidateInput) else {
                showError("That doesn’t look like Secure ciphertext (Base64 blob)."); return
            }
            do {
                let box = try SecureBox(base64Key: secureKey.trimmingCharacters(in: .whitespacesAndNewlines))
                let data = try box.open(candidateInput)
                output = String(data: data, encoding: .utf8) ?? "Decrypted (non-UTF8 data)"
                addHistory(action: "Decrypt")
            } catch {
                showError("Secure decrypt error: wrong key or corrupted blob.")
            }

        case .xor:
            guard let intKey = Int(xorKey.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                showError("Invalid XOR key. Enter a single integer (e.g. 357)."); return
            }
            guard isLikelyBase64(candidateInput) else {
                showError("That doesn’t look like XOR ciphertext (Base64)."); return
            }
            if let plain = decryptMessage(candidateInput, intKey) {
                output = plain
                addHistory(action: "Decrypt")
            } else {
                showError("Decryption failed. Check Base64 and key.")
            }
        }
    }

    private func addHistory(action: String) {
        let modeName = (mode == .secure ? "Secure" : "XOR")
        let keyHint: String = {
            switch mode {
            case .secure: return String(secureKey.prefix(6))
            case .xor:    return String(xorKey.prefix(6))
            }
        }()
        historyStore.add(.init(
            date: Date(),
            mode: modeName,
            action: action,
            keyHint: keyHint,
            inputPreview: String(message.prefix(40)),
            outputPreview: String(output.prefix(40))
        ))
    }
}

// MARK: - Scroll auto-dismiss support
struct ScrollDismissModifier: ViewModifier {
    var focus: FocusState<KryptField?>.Binding
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.immediately)
        } else {
            content.simultaneousGesture(
                DragGesture().onChanged { _ in focus.wrappedValue = nil }
            )
        }
    }
}

// MARK: - Subviews
private struct SecureKeySection: View {
    @Binding var keyInput: String
    var toast: (String) -> Void
    var strengthOK: Bool
    var focus: FocusState<KryptField?>.Binding

    var body: some View {
        Group {
            HStack {
                Text("Secure Key").kryptHeader()
                Spacer()
                Button {
                    keyInput = SecureBox.generateBase64Key()
                    toast("Generated 256-bit key")
                } label: {
                    Label("Generate Key", systemImage: "wand.and.stars")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            TextField("Paste or generate a key…", text: $keyInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.asciiCapable)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
                .focused(focus, equals: .key)

            HStack(spacing: 8) {
                Circle().fill(strengthOK ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(strengthOK ? "Key looks valid (32-byte Base64)" : "Invalid key format")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()

                Button {
                    let ok = KeychainHelper.saveKey(keyInput)
                    toast(ok ? "Saved to Keychain" : "Save failed")
                } label: {
                    Label("Save", systemImage: "key.horizontal")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button {
                    if let k = KeychainHelper.loadKey() {
                        keyInput = k
                        toast("Loaded from Keychain")
                    } else {
                        toast("No key in Keychain")
                    }
                } label: {
                    Label("Load", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

        }
    }
}

private struct ToyKeySection: View {
    let mode: CipherMode
    @Binding var keyInput: String
    var focus: FocusState<KryptField?>.Binding

    var body: some View {
        Group {
            Text("Key (single integer, e.g. 357)")
                .kryptHeader()
            TextField("Enter key…", text: $keyInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.numbersAndPunctuation)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
                .focused(focus, equals: .key)
        }
    }
}
