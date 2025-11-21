import SwiftUI

struct UsernameSetupView: View {
    @Environment(\.serviceLocator) private var services
    @State private var name = ""
    @State private var errorMessage: String?
    @State private var busy = false
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Pick a username").font(.title2.bold())
            TextField("@username", text: $name)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let e = errorMessage {
                Text(e)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await save() }
            } label: {
                Text(busy ? "Saving…" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(busy || name.isEmpty)
        }
        .padding()
    }

    @MainActor
    private func save() async {
        errorMessage = nil
        busy = true
        do {
            let uid = try await services.auth.ensureSignedIn()
            try await services.users.setUsername(uid: uid, raw: name)
            onDone()
        } catch {
            // you can also inspect `error` if you want
            errorMessage = "Username not available. Try another."
        }
        busy = false
    }
}
