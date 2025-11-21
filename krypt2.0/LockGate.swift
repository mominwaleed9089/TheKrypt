import SwiftUI
import LocalAuthentication

struct LockGate: View {
    @Binding var unlocked: Bool
    @State private var errorText: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.largeTitle)
            Text("Unlock Krypt").font(.title3.bold())

            if let e = errorText {
                Text(e)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                authenticateBiometrics()
            } label: {
                Label("Use Face ID / Touch ID", systemImage: "faceid")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)

            Button {
                authenticatePasscode()
            } label: {
                Label("Use Device Passcode", systemImage: "key.fill")
            }
            .buttonStyle(.bordered)
            .disabled(isAuthenticating)
        }
        .padding()
        .onAppear { authenticateBiometrics() }
    }

    private func authenticateBiometrics() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"
        var authError: NSError?

        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Unlock Krypt") { success, error in
                DispatchQueue.main.async {
                    if success {
                        unlocked = true
                    } else {
                        if let laErr = error as? LAError, laErr.code == .biometryLockout {
                            // Immediate fallback to passcode if locked out
                            authenticatePasscode()
                        } else {
                            errorText = "Face ID failed. Try again or use passcode."
                        }
                    }
                }
            }
        } else {
            // Fallback if Face ID/Touch ID not available
            authenticatePasscode()
        }
    }

    private func authenticatePasscode() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"
        ctx.evaluatePolicy(.deviceOwnerAuthentication,
                           localizedReason: "Unlock Krypt") { success, _ in
            DispatchQueue.main.async {
                if success {
                    unlocked = true
                } else {
                    errorText = "Passcode authentication canceled or failed."
                }
            }
        }
    }
}
