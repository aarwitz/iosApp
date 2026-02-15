import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(store.chat) { msg in
                            HStack {
                                if msg.isMe { Spacer(minLength: 24) }
                                Text(msg.text)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.95))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(msg.isMe ? 0.12 : 0.07))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                if !msg.isMe { Spacer(minLength: 24) }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    if let last = store.chat.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: store.chat.count) { _ in
                    if let last = store.chat.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider().overlay(EPTheme.divider)

            HStack(spacing: 10) {
                TextField("Write something…", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))

                Button {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.addChatMessage(text: trimmed)
                    draft = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(12)
                        .background(Circle().fill(EPTheme.accent))
                }
                .accessibilityLabel("Send")
            }
            .padding(12)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}
