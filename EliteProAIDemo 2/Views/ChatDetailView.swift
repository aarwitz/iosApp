import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: String = ""
    @State private var isSending: Bool = false
    let conversation: Conversation
    
    private var messages: [ChatMessage] {
        store.conversations.first(where: { $0.id == conversation.id })?.messages ?? conversation.messages
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isMe { Spacer(minLength: 24) }
                                Text(msg.text)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(Color.primary.opacity(0.95))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(EPTheme.card)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(EPTheme.cardStroke, lineWidth: 1)
                                    )
                                if !msg.isMe { Spacer(minLength: 24) }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
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
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))

                Button {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let msgText = trimmed
                    draft = ""
                    isSending = true
                    Task {
                        await store.addChatMessage(to: conversation.id, text: msgText)
                        isSending = false
                    }
                } label: {
                    if isSending {
                        ProgressView()
                            .frame(width: 20, height: 20)
                            .padding(8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(Color.black.opacity(0.85))
                            .padding(12)
                            .background(Circle().fill(EPTheme.accent))
                    }
                }
                .accessibilityLabel("Send")
                .disabled(isSending)
            }
            .padding(12)
        }
        .navigationTitle(conversation.contactName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
