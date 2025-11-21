import SwiftUI

struct ChatLauncherView: View {
    @Environment(\.serviceLocator) private var services

    @State private var username: String = ""
    @State private var xorKey: String = "demo-xor-key"
    @State private var errorMessage: String?
    @State private var busy = false
    @State private var goToChat = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Demo Chat Room")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 12) {
                Text("Your username")
                    .font(.subheadline.weight(.semibold))

                TextField("@username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("Shared XOR key (demo only)")
                    .font(.subheadline.weight(.semibold))

                TextField("secret-key", text: $xorKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let e = errorMessage {
                Text(e)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await continueTapped() }
            } label: {
                Text(busy ? "Please wait…" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(busy || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()

            NavigationLink("", isActive: $goToChat) {
                ChatRoomView(roomId: "demo-room", xorPass: xorKey)
            }
            .hidden()
        }
        .padding()
        .navigationTitle("Start Demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func continueTapped() async {
        errorMessage = nil
        busy = true
        do {
            let uid = try await services.auth.ensureSignedIn()
            try await services.users.setUsername(uid: uid, raw: username)
            goToChat = true
        } catch {
            errorMessage = "Username must be at least 3 characters."
        }
        busy = false
    }
}
