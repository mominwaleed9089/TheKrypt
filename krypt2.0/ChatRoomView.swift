import SwiftUI

struct ChatRoomView: View {
    @Environment(\.serviceLocator) private var services

    let roomId: String
    let xorPass: String

    @StateObject private var chat = OfflineChatService()

    var body: some View {
        VStack(spacing: 8) {
            Label("Educational XOR mode — not secure for real data.", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .padding(8)
                .background(Color.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chat.items) { m in
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(m.plaintext ?? "🔒 Encrypted (wrong key?)")
                                        .foregroundStyle(m.plaintext == nil ? .secondary : .primary)
                                    Text("\(m.remaining)s")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .id(m.id)
                            .transition(.asymmetric(                 // <<< how it appears / disappears
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                    .animation(.easeInOut(duration: 0.3), value: chat.items)   // <<< apply animation
                }

                .onChange(of: chat.items.count) { _, _ in
                    if let last = chat.items.last?.id {
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Message…", text: $chat.inputText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task {
                        let trimmed = chat.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        try? await chat.send(roomId: roomId, text: trimmed, xorPass: xorPass)
                        chat.inputText = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("Room")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            chat.listen(roomId: roomId, xorPass: xorPass)
        }
        .onDisappear {
            chat.stop()
        }
    }
}
