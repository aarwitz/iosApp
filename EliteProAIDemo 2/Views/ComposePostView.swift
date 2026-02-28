import SwiftUI

struct ComposePostView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var postText: String = ""
    @State private var selectedCommunity: String = ""
    @State private var selectedGroup: String = ""
    @State private var isPosting: Bool = false

    private var availableGroups: [Group] {
        if selectedCommunity.isEmpty {
            return store.communities.flatMap { $0.groups }
        }
        return store.communities.first(where: { $0.name == selectedCommunity })?.groups ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Community") {
                    Picker("Community", selection: $selectedCommunity) {
                        Text("All Communities").tag("")
                        ForEach(store.communities, id: \.name) { community in
                            Text(community.name).tag(community.name)
                        }
                    }
                    .onChange(of: selectedCommunity) { newValue, oldValue in
                        if !availableGroups.contains(where: { $0.name == selectedGroup }) {
                            selectedGroup = availableGroups.first?.name ?? ""
                        }
                    }
                }

                Section("Group") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("Select a group…").tag("")
                        ForEach(availableGroups) { group in
                            Text(group.name).tag(group.name)
                        }
                    }
                }

                Section("What's on your mind?") {
                    TextField("Write your post…", text: $postText, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isPosting = true
                        Task {
                            await store.addPost(
                                groupName: selectedGroup,
                                text: postText.trimmingCharacters(in: .whitespacesAndNewlines),
                                communityName: selectedCommunity
                            )
                            store.earnCredits(1)
                            isPosting = false
                            dismiss()
                        }
                    } label: {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedGroup.isEmpty || isPosting)
                }
            }
            .onAppear {
                if let first = store.communities.first {
                    selectedCommunity = first.name
                    selectedGroup = first.groups.first?.name ?? ""
                }
            }
        }
    }
}
