import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedCategory: ChallengeCategory = .recommended

    var filteredChallenges: [Challenge] {
        store.challenges.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: – Header
                EPCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 24))
                                .foregroundStyle(EPTheme.accent)
                            Text("Challenges")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }
                        Text("Push yourself, compete with friends, and earn credits.")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.subheadline, design: .rounded))
                    }
                }

                // MARK: – Category Picker
                HStack(spacing: 0) {
                    ForEach(ChallengeCategory.allCases, id: \.rawValue) { cat in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = cat
                            }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(.subheadline, design: .rounded).weight(selectedCategory == cat ? .bold : .regular))
                                .foregroundStyle(selectedCategory == cat ? Color.primary : EPTheme.softText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedCategory == cat ? EPTheme.accent.opacity(0.25) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))

                // MARK: – Challenge Cards
                ForEach(filteredChallenges) { challenge in
                    challengeCard(challenge)
                }

                if filteredChallenges.isEmpty {
                    EPCard {
                        VStack(spacing: 8) {
                            Image(systemName: "trophy")
                                .font(.system(size: 36))
                                .foregroundStyle(EPTheme.softText)
                            Text("No challenges yet in this category")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Single Challenge Card

    private func challengeCard(_ challenge: Challenge) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 10) {

                // Image placeholder area
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [EPTheme.accent.opacity(0.15), EPTheme.accent.opacity(0.05)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    Image(systemName: challenge.imagePlaceholder)
                        .font(.system(size: 44))
                        .foregroundStyle(EPTheme.accent.opacity(0.6))
                }

                // Title + subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.system(.headline, design: .rounded))
                    Text(challenge.subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(2)
                }

                // Community / Friend tag
                if let community = challenge.communityName {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(EPTheme.accent)
                        Text(community)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.accent)
                    }
                }
                if let friend = challenge.friendName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.blue.opacity(0.8))
                        Text(friend)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(Color.blue.opacity(0.8))
                    }
                }

                // Progress bar
                if challenge.progress > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: challenge.progress)
                            .tint(EPTheme.accent)
                            .scaleEffect(x: 1.0, y: 1.5, anchor: .center)
                        Text("\(Int(challenge.progress * 100))% complete")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                // Join / Earn Button
                HStack {
                    Spacer()
                    Button {
                        store.earnCredits(5)
                    } label: {
                        Text(challenge.progress > 0 ? "Continue" : "Join Challenge")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(EPTheme.accent))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
