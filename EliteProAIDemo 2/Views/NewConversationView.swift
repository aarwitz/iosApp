// NewConversationView.swift
// EliteProAIDemo
//
// Sheet that lets the current user pick a friend to message.
// Calls the completion handler with the resulting Conversation so the
// parent can navigate to ChatDetailView.

import SwiftUI

struct NewConversationView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let onConversationReady: (Conversation) -> Void

    @State private var searchText: String = ""
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?

    private var filteredFriends: [FriendProfile] {
        if searchText.isEmpty {
            return store.friends
        }
        return store.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if store.friends.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredFriends) { friend in
                            Button {
                                startConversation(with: friend)
                            } label: {
                                friendRow(friend)
                            }
                            .listRowBackground(EPTheme.card)
                            .disabled(isCreating)
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search friends")
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isCreating {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Opening chat…")
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 14).fill(EPTheme.card))
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: – Friend Row

    private func friendRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(EPTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(friend.avatarInitials)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(EPTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.primary)

                if !friend.buildingName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: 10))
                        Text(friend.buildingName)
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(EPTheme.softText)
                } else if !friend.bio.isEmpty {
                    Text(friend.bio)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(EPTheme.softText)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: – Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 56))
                .foregroundStyle(EPTheme.softText.opacity(0.5))
            Text("No Friends Yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Add friends using the Find Friends or Scan Code features to start messaging.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: – Start Conversation

    private func startConversation(with friend: FriendProfile) {
        isCreating = true
        Task {
            let conversation = await store.getOrCreateConversation(with: friend)
            await MainActor.run {
                isCreating = false
                dismiss()
                onConversationReady(conversation)
            }
        }
    }
}
