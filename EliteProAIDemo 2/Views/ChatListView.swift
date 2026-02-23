import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showNewConversation: Bool = false
    @State private var navigationTarget: Conversation?

    var body: some View {
        ZStack {
            if store.conversations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.conversations) { conversation in
                            NavigationLink {
                                ChatDetailView(conversation: conversation)
                            } label: {
                                conversationRow(conversation)
                            }
                            .buttonStyle(.plain)

                            if conversation.id != store.conversations.last?.id {
                                Divider()
                                    .overlay(EPTheme.divider)
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable { await store.refreshConversations() }
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
                    Text(conversation.lastMessage)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
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
