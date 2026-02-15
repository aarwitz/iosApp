import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject private var store: AppStore

    private let challenges: [(String, String, Int)] = [
        ("7-day Steps Streak", "Hit 8k steps daily", 10),
        ("Hydration Week", "2L water per day", 10),
        ("Mobility Minutes", "10 minutes mobility", 5)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Challenges")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Text("Complete challenges to earn credits.")
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                ForEach(challenges, id: \.0) { c in
                    EPCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(c.0).font(.system(.headline, design: .rounded))
                                Text(c.1).font(.system(.subheadline, design: .rounded)).foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            Button("+\(c.2)") {
                                store.earnCredits(c.2)
                            }
                            .tint(EPTheme.accent)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }
}
