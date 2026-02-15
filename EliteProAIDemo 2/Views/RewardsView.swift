import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rewards")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Text("Earn credits from healthy habits and redeem perks. (Demo only)")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.subheadline, design: .rounded))
                        ProgressView(value: Double(store.credits.current), total: Double(store.credits.goal))
                            .tint(EPTheme.accent)
                            .scaleEffect(x: 1.0, y: 2.0, anchor: .center)

                        Text("\(store.credits.current) credits available")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.footnote, design: .rounded))
                    }
                }

                ForEach(rewardOptions, id: \.title) { r in
                    EPCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(r.title)
                                    .font(.system(.headline, design: .rounded))
                                Text(r.subtitle)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            Button("Redeem") {
                                // demo: spend credits
                                store.credits.current = max(0, store.credits.current - r.cost)
                                store.persist()
                            }
                            .tint(EPTheme.accent)
                            .disabled(store.credits.current < r.cost)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Reward: Hashable {
        let title: String
        let subtitle: String
        let cost: Int
    }

    private var rewardOptions: [Reward] {
        [
            Reward(title: "Free group class", subtitle: "1 credit pack for a scheduled class", cost: 30),
            Reward(title: "Trainer discount", subtitle: "$10 off your next session", cost: 50),
            Reward(title: "Community perk", subtitle: "Unlock building challenge badge", cost: 20)
        ]
    }
}
