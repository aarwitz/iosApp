import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: String = ""
    @State private var isSending: Bool = false
    @State private var refreshTimer: Timer? = nil
    @State private var messageToDelete: ChatMessage? = nil
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
                                VStack(alignment: msg.isMe ? .trailing : .leading, spacing: 4) {
                                    Text(msg.text)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(Color.primary.opacity(0.95))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(msg.isMe ? EPTheme.accent.opacity(0.18) : EPTheme.card)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(msg.isMe ? EPTheme.accent.opacity(0.3) : EPTheme.cardStroke, lineWidth: 1)
                                        )
                                    
                                    if !msg.isMe {
                                        Text(msg.from)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(EPTheme.softText)
                                    }
                                    
                                    Text(msg.timestamp, style: .time)
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundStyle(EPTheme.softText.opacity(0.6))
                                }
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = msg.text
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    Button(role: .destructive) {
                                        messageToDelete = msg
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
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
                    // Fetch latest messages from server on appear
                    Task {
                        await store.refreshMessages(for: conversation.id)
                    }
                    // Auto-refresh every 5 seconds for near-real-time chat
                    refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                        Task { @MainActor in
                            await store.refreshMessages(for: conversation.id)
                        }
                    }
                }
                .onDisappear {
                    refreshTimer?.invalidate()
                    refreshTimer = nil
                    // Refresh conversation list so preview is up-to-date
                    Task { await store.refreshConversations() }
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
        .alert(
            "Delete Message",
            isPresented: Binding(
                get: { messageToDelete != nil },
                set: { if !$0 { messageToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let msg = messageToDelete {
                    Task { await store.deleteMessage(msg.id, in: conversation.id) }
                }
                messageToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                messageToDelete = nil
            }
        } message: {
            Text("This message will be removed from your view only.")
        }
    }
}
