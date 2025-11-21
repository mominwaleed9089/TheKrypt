import SwiftUI

// MARK: - Saved identity model

struct SavedIdentity: Identifiable, Codable, Equatable {
    var id = UUID()
    var username: String
    var xorKey: String
}

extension SavedIdentity {
    static func load(from string: String) -> [SavedIdentity] {
        guard let data = string.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SavedIdentity].self, from: data)) ?? []
    }

    static func dump(_ items: [SavedIdentity]) -> String {
        (try? String(data: JSONEncoder().encode(items), encoding: .utf8)) ?? "[]"
    }
}

// MARK: - Main view

struct UserSearchView: View {
    @Environment(\.serviceLocator) private var services

    // Persisted list of saved identities
    @AppStorage("kryptSavedIdentities") private var savedRaw: String = "[]"
    @State private var saved: [SavedIdentity] = []

    // Current inputs (reset on appear)
    @State private var username: String = ""
    @State private var xorPass: String = ""

    @State private var errorMessage: String?
    @State private var busy = false

    @State private var navRoomId: String?
    @State private var navigateToRoom = false

    @State private var showSavedList = false
    @State private var showInvalidXorAlert = false

    // Check if this username already exists in saved list
    private var existingSaved: SavedIdentity? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return saved.first {
            $0.username.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if AppConfig.offlineDemo {
                Label(AppConfig.offlineBanner, systemImage: "wifi.slash")
                    .font(.footnote.weight(.semibold))
                    .padding(8)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Title + description
            VStack(alignment: .leading, spacing: 8) {
                Text("Demo Chat Room")
                    .font(.title.bold())

                Text("Choose a username and a numeric XOR key. This is just for demo; nothing is stored or sent to any server.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

            // Fields
            VStack(alignment: .leading, spacing: 12) {
                Text("Your username")
                    .font(.subheadline.weight(.semibold))

                TextField("@username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Shared XOR key (numbers only)")
                    .font(.subheadline.weight(.semibold))

                TextField("Enter-Key", text: $xorPass)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: xorPass) { newValue in
                        // keep only digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            xorPass = filtered
                            showInvalidXorAlert = true
                        }
                    }
            }

            // Saved / Clear / Save row
            HStack {
                Button {
                    showSavedList = true
                } label: {
                    Label("Saved", systemImage: "list.bullet")
                }

                // Show "Clear all" ONLY when there is something saved
                if !saved.isEmpty {
                    Button(role: .destructive) {
                        clearAllSaves()
                    } label: {
                        Text("Clear all")
                    }
                }

                Spacer()

                // Show Save button only if this username+key is new and non-empty
                if existingSaved == nil &&
                    !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    !xorPass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                    Button("Save") {
                        saveCurrentIdentity()
                    }
                }
            }
            .font(.footnote)

            if let e = errorMessage {
                Text(e)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            // Continue into chat
            Button {
                Task { await startDemoChat() }
            } label: {
                Text(busy ? "Please wait…" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                busy ||
                username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                xorPass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )

            // Hidden navigation into ChatRoomView
            if let rid = navRoomId {
                NavigationLink(isActive: $navigateToRoom) {
                    ChatRoomView(roomId: rid, xorPass: xorPass)
                } label: {
                    EmptyView()
                }
                .hidden()
            }
        }
        .padding()
        .navigationTitle("Start Demo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            saved = SavedIdentity.load(from: savedRaw)
            username = ""
            xorPass = ""
            errorMessage = nil
        }
        .sheet(isPresented: $showSavedList) {
            SavedIdentitiesSheet(
                saved: $saved,
                onPick: { identity in
                    username = identity.username
                    xorPass = identity.xorKey
                },
                onChange: persistSavedIdentities
            )
        }
        .alert("Invalid key", isPresented: $showInvalidXorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("XOR key must contain numbers only.")
        }
    }

    // MARK: - Persistence helpers

    private func persistSavedIdentities() {
        savedRaw = SavedIdentity.dump(saved)
    }

    private func saveCurrentIdentity() {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedXor  = xorPass.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUser.isEmpty, !trimmedXor.isEmpty else { return }
        guard existingSaved == nil else { return }

        saved.append(SavedIdentity(username: trimmedUser, xorKey: trimmedXor))
        persistSavedIdentities()
    }

    private func clearAllSaves() {
        saved.removeAll()
        persistSavedIdentities()
    }

    // MARK: - Start chat

    private func startDemoChat() async {
        errorMessage = nil
        busy = true

        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedXor  = xorPass.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedUser.count >= 3 else {
            errorMessage = "Username must be at least 3 characters."
            busy = false
            return
        }
        guard !trimmedXor.isEmpty else {
            errorMessage = "Please enter a shared XOR key."
            busy = false
            return
        }

        // If this username is saved, enforce matching key
        if let savedIdentity = existingSaved {
            if savedIdentity.xorKey != trimmedXor {
                errorMessage = "Wrong key for this user."
                busy = false
                return
            }
        }

        do {
            let uid = try await services.auth.ensureSignedIn()
            try await services.users.setUsername(uid: uid, raw: trimmedUser)

            let roomId = try await services.rooms.ensureRoom(uid: uid, peerUid: "demo-peer")
            navRoomId = roomId
            navigateToRoom = true
        } catch {
            errorMessage = "Something went wrong starting the demo."
        }

        busy = false
    }
}

// MARK: - Saved identities sheet

private struct SavedIdentitiesSheet: View {
    @Binding var saved: [SavedIdentity]
    var onPick: (SavedIdentity) -> Void
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(saved) { item in
                    Button {
                        onPick(item)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.username)
                                .font(.body)
                            Text(item.xorKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    saved.remove(atOffsets: indexSet)
                    onChange()
                }
            }
            .navigationTitle("Saved identities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
