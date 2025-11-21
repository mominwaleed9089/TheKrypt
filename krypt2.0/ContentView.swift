import SwiftUI

// ──────────────────────────────────────────────────────────────
// Theme (inline so this file compiles standalone).
// ──────────────────────────────────────────────────────────────
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
}
enum AccentChoice: String, CaseIterable, Identifiable {
    case blue, green, purple, orange, pink, mint, cyan, indigo
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .mint: return .mint
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
}
struct ThemeApplier: ViewModifier {
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @AppStorage("accentChoice") private var accentChoice = AccentChoice.blue.rawValue
    func body(content: Content) -> some View {
        content
            .preferredColorScheme({
                switch AppTheme(rawValue: appTheme) ?? .system {
                case .system: return nil
                case .light:  return .light
                case .dark:   return .dark
                }
            }())
            .tint(AccentChoice(rawValue: accentChoice)?.color ?? .blue)
    }
}
extension View { func applyAppTheme() -> some View { modifier(ThemeApplier()) } }
// ──────────────────────────────────────────────────────────────

enum CipherMode: String, CaseIterable, Identifiable {
    case secure = "Secure (ChaCha20-Poly1305)"
    case xor = "XOR (numeric key)"
//    case multishift = "Multi-Shift (number list)"
    var id: String { rawValue }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme

    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @State private var unlocked = false
    @State private var showLock = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("The Krypt")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(scheme == .dark ? 0.6 : 0.1), radius: 6)

                    Text("Encrypt • Decrypt • Repeat")
                        .foregroundStyle(.secondary)

                    // Existing main button → Workspace
                    NavigationLink { KryptWorkspaceView() } label: {
                        Text("Enter")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(scheme == .dark ? .white : .primary)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().strokeBorder(borderStroke, lineWidth: 1))
                            .shadow(color: shadowColor, radius: 8)
                    }
                    .buttonStyle(PressableStyle())

                    // NEW: Chatroom button → your chat flow
                    NavigationLink { EnterRoomRootView() } label: {
                        Text("Chatroom")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(scheme == .dark ? .white : .primary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 32)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().strokeBorder(borderStroke, lineWidth: 1))
                            .shadow(color: shadowColor, radius: 6)
                    }
                    .buttonStyle(PressableStyle())
                }

                VStack {
                    Spacer()
                    HStack {
                        NavigationLink { HowToView() } label: {
                            CornerIcon(letter: "i", label: "How to", scheme: scheme)
                        }
                        .buttonStyle(PressableStyle(scale: 0.92))
                        Spacer()
                        NavigationLink { AboutView() } label: {
                            CornerIcon(letter: "?", label: "About", scheme: scheme)
                        }
                        .buttonStyle(PressableStyle(scale: 0.92))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .applyAppTheme()
        .fullScreenCover(isPresented: $showLock) {
            LockGate(unlocked: $unlocked)
        }
        .onAppear {
            if appLockEnabled && !unlocked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showLock = true
                }
            }
        }
        .onChange(of: appLockEnabled) { _, enabled in
            if enabled {
                unlocked = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showLock = true
                }
            } else {
                unlocked = true
                showLock = false
            }
        }
        .onChange(of: unlocked) { _, isUnlocked in
            if isUnlocked { showLock = false }
        }
    }

    private var backgroundGradient: LinearGradient {
        if scheme == .dark {
            LinearGradient(colors: [.black, Color(white: 0.12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [Color(uiColor: .systemBackground),
                                    Color(uiColor: .secondarySystemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    private var borderStroke: Color { scheme == .dark ? .white.opacity(0.12) : .black.opacity(0.12) }
    private var shadowColor: Color { scheme == .dark ? .black.opacity(0.5) : .black.opacity(0.15) }
}

// MARK: - Corner icon
private struct CornerIcon: View {
    let letter: String
    let label: String
    var scheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(borderStroke, lineWidth: 1))
                    .shadow(color: shadowColor, radius: scheme == .dark ? 6 : 4, x: 0, y: 2)
                Text(letter)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
    }
    private var borderStroke: Color { scheme == .dark ? .white.opacity(0.12) : .black.opacity(0.12) }
    private var shadowColor: Color { scheme == .dark ? .black.opacity(0.45) : .black.opacity(0.15) }
}

// MARK: - Press animation
private struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var spring: Animation = .spring(response: 0.22, dampingFraction: 0.8, blendDuration: 0.2)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(spring, value: configuration.isPressed)
    }
}
