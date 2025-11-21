import SwiftUI

struct SettingsView: View {
    @AppStorage("autoClearAfterEncrypt") private var autoClearAfterEncrypt = true
    @AppStorage("autoCopyAfterEncrypt")  private var autoCopyAfterEncrypt  = false
    @AppStorage("autoLoadSecureKeyOnLaunch") private var autoLoadSecureKeyOnLaunch = true

    @AppStorage("appTheme")       private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("accentChoice")   private var accentChoice: String = AccentChoice.blue.rawValue
    @AppStorage("outputFormat")   private var outputFormat: String = OutputFormat.base64.rawValue
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    private let privacyURL = URL(string: "https://www.apple.com/legal/privacy/data/en/messages/")!

    private var supportURL: URL {
        let device = UIDevice.current.model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let ios = UIDevice.current.systemVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "\n\n---\nDevice: \(device)\niOS Version: \(ios)\nApp Version: \(appVersion)\nIssue:"
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded = "Krypt Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:mominwaleed9089@gmail.com?subject=\(subjectEncoded)&body=\(bodyEncoded)")!
    }

    @StateObject private var history = HistoryStore()

    var body: some View {
        Form {
            Section(header: Text("Appearance").kryptSectionHeader()) {
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("Accent", selection: $accentChoice) {
                    ForEach(AccentChoice.allCases) { Text($0.rawValue.capitalized).tag($0.rawValue) }
                }
            }

            Section(header: Text("Behavior").kryptSectionHeader()) {
                Toggle("Auto-clear Message after Encrypt", isOn: $autoClearAfterEncrypt)
                Toggle("Auto-copy Output after Encrypt", isOn: $autoCopyAfterEncrypt)
                Toggle("Auto-load Secure Key on Launch", isOn: $autoLoadSecureKeyOnLaunch)
                Picker("Output Format", selection: $outputFormat) {
                    ForEach(OutputFormat.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Toggle("App Lock (Face ID / Touch ID)", isOn: $appLockEnabled)
            }

            Section(header: Text("Help & Legal").kryptSectionHeader()) {
                Link(destination: privacyURL) { Label("Privacy Policy", systemImage: "hand.raised") }
                Link(destination: supportURL) { Label("Contact Support", systemImage: "envelope") }
            }

            Section(header: Text("History").kryptSectionHeader(),
                    footer: Text("Keeps the last 10 operations on-device.")
                        .font(.footnote).foregroundStyle(.secondary)) {
                Button(role: .destructive) {
                    history.clear()
                } label: { Label("Clear History", systemImage: "trash") }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .applyAppTheme()
        .dynamicTypeSize(.small ... .accessibility3) // Accessibility-friendly range
    }
}
