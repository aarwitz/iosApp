import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var name: String = ""
    @State private var kind: GroupKind = .region
    @State private var location: String = "Boston • Seaport"

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Create a Group")
                            .font(.system(.headline, design: .rounded))
                        TextField("Group name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        Picker("Type", selection: $kind) {
                            ForEach(GroupKind.allCases, id: \.self) { k in
                                Text(k.rawValue).tag(k)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField("Location hint", text: $location)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            store.groups.insert(Group(name: trimmed, kind: kind, locationHint: location, members: 1), at: 0)
                            store.persist()
                            store.earnCredits(12)
                            name = ""
                        } label: {
                            Text("Create (Demo)")
                        }
                        .buttonStyle(EPButtonStyle())

                        Text("Creating a group earns credits in this demo.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
    }
}
