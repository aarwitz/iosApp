import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedEarningCategory: EarningCategory = .sponsored
    @State private var selectedRewardCategory: RewardCategory = .fitness
    @State private var showRedeemSuccess = false
    @State private var lastRedeemedItem: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Credits overview card
                creditsOverviewCard
                
                // Ways to earn section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ways to Earn")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 16)
                    
                    // Category selector
                    earningCategorySelector
                    
                    // Earning opportunities
                    ForEach(filteredEarningOpportunities) { opportunity in
                        earningOpportunityCard(opportunity)
                    }
                }
                
                Divider()
                    .overlay(EPTheme.divider)
                    .padding(.vertical, 8)
                
                // Redeem rewards section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Redeem Rewards")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 16)
                    
                    // Category selector
                    rewardCategorySelector
                    
                    // Reward items
                    ForEach(filteredRewardItems) { reward in
                        rewardItemCard(reward)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChatListView()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 18, weight: .semibold))
                        let unreadCount = store.conversations.reduce(0) { $0 + $1.unreadCount }
                        if unreadCount > 0 {
                            Circle()
                                .fill(EPTheme.accent)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
        .alert("Reward Redeemed!", isPresented: $showRedeemSuccess) {
            Button("Nice!", role: .cancel) { }
        } message: {
            Text("You've successfully redeemed: \(lastRedeemedItem)")
        }
    }
    
    // MARK: - Credits Overview
    
    private var creditsOverviewCard: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Credits")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Text("Earn from activities, redeem for perks")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    
                    Spacer()
                    
                    // Credits badge
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(EPTheme.accent.opacity(0.15))
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(EPTheme.accent)
                        }
                        .frame(width: 56, height: 56)
                        
                        Text("\(store.credits.current)")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.primary)
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress to next milestone")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                        Spacer()
                        Text("\(store.credits.current)/\(store.credits.goal)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(EPTheme.softText)
                    }
                    
                    ProgressView(value: Double(store.credits.current), total: Double(store.credits.goal))
                        .tint(EPTheme.accent)
                        .scaleEffect(x: 1.0, y: 2.0, anchor: .center)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Earning Section
    
    private var earningCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EarningCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedEarningCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(selectedEarningCategory == category ? .black : Color.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedEarningCategory == category ? EPTheme.accent : EPTheme.card)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var filteredEarningOpportunities: [EarningOpportunity] {
        store.earningOpportunities
            .filter { $0.category == selectedEarningCategory && !$0.isCompleted }
    }
    
    @ViewBuilder
    private func earningOpportunityCard(_ opportunity: EarningOpportunity) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(EPTheme.accent.opacity(0.15))
                        Image(systemName: opportunity.imagePlaceholder)
                            .font(.system(size: 24))
                            .foregroundStyle(EPTheme.accent)
                    }
                    .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(opportunity.title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        
                        if let sponsor = opportunity.sponsorName {
                            HStack(spacing: 4) {
                                Image(systemName: opportunity.sponsorLogo)
                                    .font(.system(size: 10))
                                Text(sponsor)
                                    .font(.system(.caption2, design: .rounded))
                            }
                            .foregroundStyle(EPTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(EPTheme.accent.opacity(0.15))
                            )
                        }
                        
                        Text(opportunity.description)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                
                Divider().overlay(EPTheme.divider)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Requirements")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                        Text(opportunity.requirements)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(Color.primary)
                    }
                    
                    Spacer()
                    
                    if let expires = opportunity.expiresAt {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Expires")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                            Text(timeRemaining(until: expires))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    // Reward badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("+\(opportunity.creditsReward)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(EPTheme.accent)
                    )
                }
                
                // Action button for demo
                Button {
                    store.completeEarningOpportunity(opportunity.id)
                } label: {
                    Text("Complete (Demo)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(EPTheme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(EPTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Redeem Section
    
    private var rewardCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RewardCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRewardCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(selectedRewardCategory == category ? .black : Color.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedRewardCategory == category ? EPTheme.accent : EPTheme.card)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var filteredRewardItems: [RewardItem] {
        store.rewardItems.filter { $0.category == selectedRewardCategory }
    }
    
    @ViewBuilder
    private func rewardItemCard(_ reward: RewardItem) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(EPTheme.card)
                        Image(systemName: reward.imagePlaceholder)
                            .font(.system(size: 24))
                            .foregroundStyle(Color.primary.opacity(0.9))
                    }
                    .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(reward.title)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.primary)
                            
                            if reward.isLimited {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        if let partner = reward.partnerName {
                            Text(partner)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.accent)
                        }
                        
                        Text(reward.description)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    if reward.isLimited, let quantity = reward.quantityLeft {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(quantity > 5 ? Color.green : (quantity > 0 ? Color.orange : Color.red))
                                .frame(width: 6, height: 6)
                            Text("\(quantity) left")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }
                    }
                    
                    Spacer()
                    
                    // Cost
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(reward.cost)")
                            .font(.system(.body, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(Color.primary)
                    
                    // Redeem button
                    Button {
                        if store.redeemReward(reward.id) {
                            lastRedeemedItem = reward.title
                            showRedeemSuccess = true
                        }
                    } label: {
                        Text("Redeem")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(canAfford(reward) ? .black : EPTheme.softText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(canAfford(reward) ? EPTheme.accent : EPTheme.card)
                            )
                    }
                    .disabled(!canAfford(reward) || (reward.isLimited && (reward.quantityLeft ?? 0) <= 0))
                }
            }
        }
        .padding(.horizontal, 16)
        .opacity((reward.isLimited && (reward.quantityLeft ?? 0) <= 0) ? 0.5 : 1.0)
    }
    
    // MARK: - Helper Functions
    
    private func canAfford(_ reward: RewardItem) -> Bool {
        store.credits.current >= reward.cost
    }
    
    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 1 {
            return "\(days) days"
        } else if hours > 1 {
            return "\(hours) hours"
        } else {
            return "< 1 hour"
        }
    }
}
