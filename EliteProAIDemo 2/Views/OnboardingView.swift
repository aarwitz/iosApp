// OnboardingView.swift
// EliteProAIDemo
//
// Welcome / onboarding carousel shown to first-time users.

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("figure.run.circle.fill",
         "Train Smarter",
         "Personalized coaching, workout logs, and nutrition tracking — all in one place."),
        ("person.2.circle.fill",
         "Connect Locally",
         "Find friends in your building, join group classes, and challenge your neighbors."),
        ("star.circle.fill",
         "Earn Rewards",
         "Build healthy habits, earn credits, and redeem real-world wellness perks.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 14) {
                Button {
                    showOnboarding = false
                } label: {
                    Text("Get Started")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(EPTheme.accent)
                        )
                }

                Button {
                    showOnboarding = false
                } label: {
                    Text("I already have an account")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.accent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(UIColor.systemBackground))
    }

    private func onboardingPage(_ page: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(EPTheme.accent.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(EPTheme.accent)
            }

            Text(page.title)
                .font(.system(.title, design: .rounded).weight(.bold))

            Text(page.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
