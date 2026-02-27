import SwiftUI

struct NutritionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedStaffIndex: Int? = 0
    @State private var showBooking = false
    @State private var staffToBook: StaffMember?
    @State private var showChat = false
    @State private var staffToMessage: StaffMember?
    @State private var mealCardIndex: Int = 0
    @State private var selectedTag: String? = nil
    @State private var showMealScanner = false
    @State private var showGroceryList = false

    private var chatButton: some View {
        NavigationLink {
            ChatListView()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bubble.left")
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

    private var nutritionists: [StaffMember] {
        store.staffMembers.filter { $0.role == .nutritionist }
    }

    private let dietaryTags = ["All", "Vegetarian", "High Protein", "Low Sodium", "Gluten Free", "Keto"]

    private var filteredMeals: [MealSuggestion] {
        guard let tag = selectedTag, tag != "All" else { return store.mealSuggestions }
        return store.mealSuggestions.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: – Nutritionist Carousel
                nutritionistCarousel

                // MARK: – What Should I Eat Tonight?
                whatToEatSection

                // MARK: – Eat Smart Delivery
                eatSmartDeliverySection

                // MARK: – 15-Minute Meals
                quickRecipesSection

                // MARK: – Scan Your Meal
                scanMealSection

                // MARK: – Nutritionist Tip of the Week
                nutritionistTipSection
            }
            .padding(16)
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                chatButton
            }
        }
        .sheet(isPresented: $showBooking) {
            if let staff = staffToBook {
                BookingSessionView(staff: staff)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showMealScanner) {
            mealScannerSheet
        }
        .sheet(isPresented: $showGroceryList) {
            groceryListSheet
        }
        .sheet(isPresented: $showChat) {
            if let staff = staffToMessage {
                nutritionistChatSheet(staff)
            }
        }
    }

    // MARK: – Nutritionist Carousel

    private var nutritionistCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(nutritionists.enumerated()), id: \.element.id) { idx, nutritionist in
                    nutritionistCard(nutritionist, index: idx)
                        .containerRelativeFrame(.horizontal)
                        .id(idx)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedStaffIndex)
    }

    private func nutritionistCard(_ nutritionist: StaffMember, index: Int) -> some View {
        EPCard {
            VStack(spacing: 12) {

                HStack(spacing: 14) {
                    // Avatar from Assets
                    Image(nutritionist.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.green, lineWidth: 2.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutritionist.name)
                            .font(.system(.headline, design: .rounded))
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                            Text("Nutritionist")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.12)))

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(nutritionist.shift.displayRange)
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(nutritionist.credentials, id: \.self) { cred in
                            Text(cred)
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(EPTheme.card.opacity(0.6)))
                                .foregroundStyle(Color.primary.opacity(0.8))
                        }
                    }
                }

                Text(nutritionist.bio)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Button {
                        staffToMessage = nutritionist
                        showChat = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                            Text("Message")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                        .foregroundStyle(.green)
                    }

                    Button {
                        staffToBook = nutritionist
                        showBooking = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Book")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.green))
                        .foregroundStyle(.white)
                    }
                }

                // Dots (inside card, below content)
                HStack(spacing: 6) {
                    ForEach(0..<nutritionists.count, id: \.self) { i in
                        Circle()
                            .fill((selectedStaffIndex ?? 0) == i ? .green : Color.gray.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 2)
                .opacity((selectedStaffIndex ?? 0) == index ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: selectedStaffIndex)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: – What Should I Eat Tonight?

    private var whatToEatSection: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("What Should I Eat Tonight?", systemImage: "fork.knife")
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                }

                Text("Swipe between delivery and quick recipes")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)

                // Tag filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dietaryTags, id: \.self) { tag in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedTag = tag
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(
                                            (selectedTag == tag || (selectedTag == nil && tag == "All"))
                                            ? EPTheme.accent : EPTheme.accent.opacity(0.1)
                                        )
                                    )
                                    .foregroundStyle(
                                        (selectedTag == tag || (selectedTag == nil && tag == "All"))
                                        ? .white : EPTheme.accent
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Eat Smart Delivery

    private var eatSmartDeliverySection: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🚗 Eat Smart Delivery")
                            .font(.system(.headline, design: .rounded))
                        Text("Nutritionist-approved meals delivered to you")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                }

                if filteredMeals.isEmpty {
                    Text("No meals match this filter")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(filteredMeals) { meal in
                        mealRow(meal)
                    }
                }

                // Delivery partner buttons
                HStack(spacing: 12) {
                    deliveryButton(name: "UberEats", icon: "car.fill", color: .black)
                    deliveryButton(name: "DoorDash", icon: "bicycle", color: .red)
                }
            }
        }
    }

    private func mealRow(_ meal: MealSuggestion) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(meal.nutritionistRecommended ? Color.green.opacity(0.12) : EPTheme.accent.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: meal.nutritionistRecommended ? "leaf.fill" : "fork.knife")
                    .font(.system(size: 18))
                    .foregroundStyle(meal.nutritionistRecommended ? .green : EPTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(meal.name)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    if meal.nutritionistRecommended {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
                Text(meal.restaurant)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                HStack(spacing: 4) {
                    ForEach(meal.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(EPTheme.card.opacity(0.6)))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
            }

            Spacer()

            Text(String(format: "$%.2f", meal.price))
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(EPTheme.accent)
        }
        .padding(.vertical, 4)
    }

    private func deliveryButton(name: String, icon: String, color: Color) -> some View {
        Button {
            // Demo: open delivery partner
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.08))
            )
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: – 15-Minute Meals

    private var quickRecipesSection: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("⏱ 15-Minute Meals")
                            .font(.system(.headline, design: .rounded))
                        Text("Quick, healthy recipes you can make at home")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                    Button {
                        showGroceryList = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.fill")
                            Text("Grocery List")
                        }
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(EPTheme.accent)
                    }
                }

                ForEach(store.quickRecipes) { recipe in
                    recipeRow(recipe)
                }
            }
        }
    }

    private func recipeRow(_ recipe: QuickRecipe) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(EPTheme.accent.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(EPTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    HStack(spacing: 8) {
                        Label(recipe.prepTime, systemImage: "clock")
                        Label("\(recipe.calories) cal", systemImage: "flame")
                        Label("\(recipe.protein)g protein", systemImage: "bolt.fill")
                    }
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: – Scan Your Meal

    private var scanMealSection: some View {
        Button {
            showMealScanner = true
        } label: {
            EPCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan Your Meal")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Take a photo and AI will estimate calories, protein, and macros")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(EPTheme.softText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: – Nutritionist Tip

    @ViewBuilder
    private var nutritionistTipSection: some View {
        if let nutritionist = nutritionists.first {
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(nutritionist.avatarPlaceholder)
                                .font(.system(size: 22))
                            Text("Nutritionist Tip of the Week")
                                .font(.system(.headline, design: .rounded))
                        }
                        Text(nutritionist.tipOfTheWeek ?? "Aim for half your plate to be vegetables at every meal. Small changes make a big difference.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.85))
                            .italic()
                    }
                }
            }
    }

    // MARK: – Meal Scanner Sheet

    private var mealScannerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(EPTheme.card)
                        .frame(width: 200, height: 200)
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 56))
                            .foregroundStyle(EPTheme.accent.opacity(0.6))
                        Text("Point at your meal")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                VStack(spacing: 8) {
                    Text("AI Meal Scanner")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("Take a photo or choose from library. AI will estimate nutritional info.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                HStack(spacing: 16) {
                    Button {
                        // Demo: Camera
                        store.earnCredits(3)
                        showMealScanner = false
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .buttonStyle(EPButtonStyle())

                    Button {
                        // Demo: Library
                        store.earnCredits(3)
                        showMealScanner = false
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Library")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                        .foregroundStyle(EPTheme.accent)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showMealScanner = false }
                }
            }
        }
    }

    // MARK: – Grocery List Sheet

    private var groceryListSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Based on this week's recipes, here's what you need:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .padding(.horizontal, 16)

                    let allIngredients = store.quickRecipes
                        .flatMap { $0.ingredients }
                        .reduce(into: [String: Bool]()) { $0[$1] = false }
                        .keys.sorted()

                    VStack(spacing: 0) {
                        ForEach(allIngredients, id: \.self) { item in
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(EPTheme.softText)
                                Text(item)
                                    .font(.system(.subheadline, design: .rounded))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            Divider().padding(.leading, 40)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("🛒 Smart Grocery List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showGroceryList = false }
                }
            }
        }
    }

    // MARK: – Chat Sheet

    private func nutritionistChatSheet(_ staff: StaffMember) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.green.opacity(0.6))
                Text("Chat with \(staff.name)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text("Messaging will be available in a future update. For now, book a session to connect.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button("Book Instead") {
                    showChat = false
                    staffToBook = staff
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showBooking = true
                    }
                }
                .buttonStyle(EPButtonStyle())
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showChat = false }
                }
            }
        }
    }
}
