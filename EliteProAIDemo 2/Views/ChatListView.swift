import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
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
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
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
