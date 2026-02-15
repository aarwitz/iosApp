import SwiftUI

struct GroupClassView: View {
    @EnvironmentObject private var store: AppStore

    private let classes: [(String, String)] = [
        ("HIIT Express", "30 min · Seaport Gym"),
        ("Mobility + Core", "25 min · Lobby Studio"),
        ("Beginner Strength", "45 min · Online")
    ]

    var body: some View {
        List {
            Section("Available Classes") {
                ForEach(classes, id: \.0) { c in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.0).font(.system(.headline, design: .rounded))
                            Text(c.1).font(.system(.subheadline, design: .rounded)).foregroundStyle(EPTheme.softText)
                        }
                        Spacer()
                        Button("Join") {
                            store.earnCredits(8)
                        }
                        .tint(EPTheme.accent)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Group Classes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
