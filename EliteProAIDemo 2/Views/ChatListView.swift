import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showNewConversation: Bool = false
    @State private var navigationTarget: Conversation?
    @State private var conversationToDelete: Conversation? = nil

    var body: some View {
        ZStack {
            if store.conversations.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.conversations) { conversation in
                        NavigationLink {
                            ChatDetailView(conversation: conversation)
                        } label: {
                            conversationRow(conversation)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await store.refreshConversations() }
                .onAppear { Task { await store.refreshConversations() } }
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel("New Message")
            }
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { conversation in
                navigationTarget = conversation
            }
            .environmentObject(store)
        }
        // Navigate to the new/existing conversation after sheet dismisses
        .background(
            NavigationLink(
                destination: navigationTarget.map { ChatDetailView(conversation: $0) },
                isActive: Binding(
                    get: { navigationTarget != nil },
                    set: { if !$0 { navigationTarget = nil } }
                )
            ) { EmptyView() }
        )
        .alert(
            "Delete Conversation",
            isPresented: Binding(
                get: { conversationToDelete != nil },
                set: { if !$0 { conversationToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let convo = conversationToDelete {
                    Task { await store.deleteConversation(convo.id) }
                }
                conversationToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
        } message: {
            Text("This will remove the conversation from your view. The other person will still see it.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundStyle(EPTheme.softText.opacity(0.4))
            Text("No Conversations Yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Tap the compose button to start a new conversation with a friend.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(EPTheme.accent.opacity(0.15))
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(EPTheme.accent)
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.contactName)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: conversation.lastMessageTime))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                
                HStack {
                    Text(conversation.lastMessage.isEmpty ? "No messages yet" : conversation.lastMessage)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .italic(conversation.lastMessage.isEmpty)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(EPTheme.accent)
                            Text("\(conversation.unreadCount)")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundStyle(.black)
                        }
                        .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let mins = Int(seconds / 60)
            return "\(mins)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
}
