import SwiftUI

struct CoachingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedStaffIndex: Int? = 0
    @State private var showBooking = false
    @State private var staffToBook: StaffMember?
    @State private var showChat = false
    @State private var staffToMessage: StaffMember?

    // chat button helps keep top-right icon consistent across tabs
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

    private var coaches: [StaffMember] {
        store.staffMembers.filter { $0.role == .coach }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: – Coach Carousel
                coachCarousel

                // MARK: – Your Booked Sessions
                bookedSessionsSection

                // MARK: – Today's Programs
                todaysProgramsSection

                // MARK: – Workout of the Day
                workoutOfTheDaySection

                // MARK: – Coaching Tip
                coachTipSection
            }
            .padding(16)
        }
        .navigationTitle("Coaching")
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
        .sheet(isPresented: $showChat) {
            if let staff = staffToMessage {
                coachChatSheet(staff)
            }
        }
    }

    // MARK: – Coach Carousel (all coaches with shifts)

    private var coachCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(coaches.enumerated()), id: \.element.id) { idx, coach in
                    coachCard(coach, index: idx)
                        .containerRelativeFrame(.horizontal)
                        .id(idx)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedStaffIndex)
    }

    private func coachCard(_ coach: StaffMember, index: Int) -> some View {
        EPCard {
            VStack(spacing: 12) {

                // Avatar + Name
                HStack(spacing: 14) {
                    // Avatar from Assets
                    Image(coach.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(EPTheme.accent, lineWidth: 2.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(coach.name)
                            .font(.system(.headline, design: .rounded))
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 10))
                            Text("Coach")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(EPTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(coach.shift.displayRange)
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                }

                // Credentials
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(coach.credentials, id: \.self) { cred in
                            Text(cred)
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(EPTheme.card.opacity(0.6)))
                                .foregroundStyle(Color.primary.opacity(0.8))
                        }
                    }
                }

                // Bio
                Text(coach.bio)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .lineLimit(2)

                // Action Buttons
                HStack(spacing: 12) {
                    Button {
                        staffToMessage = coach
                        showChat = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                            Text("Message")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                        .foregroundStyle(EPTheme.accent)
                    }

                    Button {
                        staffToBook = coach
                        showBooking = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Book")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(EPTheme.accent))
                        .foregroundStyle(.white)
                    }
                }

                // Dots (inside card, below content)
                HStack(spacing: 6) {
                    ForEach(0..<coaches.count, id: \.self) { i in
                        Circle()
                            .fill((selectedStaffIndex ?? 0) == i ? EPTheme.accent : Color.gray.opacity(0.4))
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

    // MARK: – Booked Sessions

    @ViewBuilder
    private var bookedSessionsSection: some View {
        let coachSessions = store.bookedSessions.filter { $0.staffRole == .coach }
        if !coachSessions.isEmpty {
            EPCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Upcoming Sessions", systemImage: "calendar")
                        .font(.system(.headline, design: .rounded))

                    ForEach(coachSessions.prefix(3)) { session in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(EPTheme.accent.opacity(0.15))
                                .frame(width: 4)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.staffName)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Text(session.date, style: .date)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            Text("\(session.durationMinutes) min")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(EPTheme.accent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: – Today's Programs

    private var todaysProgramsSection: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Today's Programs", systemImage: "flame.fill")
                    .font(.system(.headline, design: .rounded))

                ForEach(demoProgramsList, id: \.title) { prog in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(prog.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: prog.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(prog.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(prog.title)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            Text(prog.subtitle)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }
                        Spacer()
                        Text(prog.time)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.accent)
                    }
                }
            }
        }
    }

    // MARK: – Workout of the Day

    private var workoutOfTheDaySection: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Workout of the Day", systemImage: "bolt.fill")
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                    Text("35 min")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                        .foregroundStyle(EPTheme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    wodRow(exercise: "Warm-up Jog", reps: "5 min")
                    wodRow(exercise: "Goblet Squats", reps: "3 × 12")
                    wodRow(exercise: "Push-ups", reps: "3 × 15")
                    wodRow(exercise: "Plank Hold", reps: "3 × 45s")
                    wodRow(exercise: "Burpees", reps: "3 × 10")
                    wodRow(exercise: "Cool-down Stretch", reps: "5 min")
                }

                Button {
                    store.earnCredits(8)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Complete")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(EPButtonStyle())
            }
        }
    }

    private func wodRow(exercise: String, reps: String) -> some View {
        HStack {
            Image(systemName: "circle")
                .font(.system(size: 10))
                .foregroundStyle(EPTheme.softText)
            Text(exercise)
                .font(.system(.subheadline, design: .rounded))
            Spacer()
            Text(reps)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(EPTheme.accent)
        }
    }

    // MARK: – Coach Tip

    @ViewBuilder
    private var coachTipSection: some View {
        if let coach = coaches.first {
            EPCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(coach.avatarPlaceholder)
                            .font(.system(size: 22))
                        Text("Coach's Tip of the Week")
                            .font(.system(.headline, design: .rounded))
                    }
                    Text(coach.tipOfTheWeek ?? "Stay consistent – small daily efforts compound into big results.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .italic()
                }
            }
        }
    }

    // MARK: – Chat Sheet

    private func coachChatSheet(_ staff: StaffMember) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(EPTheme.accent.opacity(0.6))
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

    // MARK: – Demo Data

    private var demoProgramsList: [DemoProgram] {
        [
            DemoProgram(title: "HIIT Circuit", subtitle: "Coach Jason • All Levels", time: "7:00 AM", icon: "bolt.heart.fill", color: .red),
            DemoProgram(title: "Strength & Tone", subtitle: "Coach Andre • Intermediate", time: "12:00 PM", icon: "dumbbell.fill", color: .blue),
            DemoProgram(title: "Yoga Flow", subtitle: "Coach Sarah • All Levels", time: "6:00 PM", icon: "figure.mind.and.body", color: .purple),
            DemoProgram(title: "Boxing Basics", subtitle: "Coach Andre • Beginner", time: "7:30 PM", icon: "figure.boxing", color: .orange)
        ]
    }
}

private struct DemoProgram {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
}

// MARK: – BookingSessionView (shared between Home & Coaching)

struct BookingSessionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let staff: StaffMember

    @State private var selectedSlot: Date?
    @State private var confirmed = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Staff header
                VStack(spacing: 12) {
                    // Avatar from Assets
                    Image(staff.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(staff.role == .coach ? EPTheme.accent : .green, lineWidth: 2.5))

                    Text("Book with \(staff.name)")
                        .font(.system(.title3, design: .rounded).weight(.bold))

                    Text(staff.shift.label + " Shift · " + staff.shift.displayRange)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                if confirmed {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                        }

                        Text("Session Booked!")
                            .font(.system(.title2, design: .rounded).weight(.bold))

                        if let slot = selectedSlot {
                            Text(slot, style: .date)
                                .font(.system(.headline, design: .rounded))
                            Text(slot, style: .time)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }

                        Text("Added to your Schedule")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)

                        Button { dismiss() } label: {
                            Text("Done")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.accent))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Available Times")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    if staff.availableSlots.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundStyle(EPTheme.softText.opacity(0.5))
                            Text("No slots available today")
                                .font(.system(.headline, design: .rounded))
                            Text("Check back tomorrow — slots refresh at midnight.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(staff.availableSlots, id: \.self) { slot in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedSlot = slot
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(slot, style: .time)
                                            .font(.system(.headline, design: .rounded).weight(.semibold))
                                        Text("60 min")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(selectedSlot == slot ? .white.opacity(0.7) : EPTheme.softText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(selectedSlot == slot
                                                  ? AnyShapeStyle(LinearGradient(colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                  : AnyShapeStyle(EPTheme.card))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedSlot == slot ? EPTheme.accent : EPTheme.cardStroke, lineWidth: selectedSlot == slot ? 2 : 1)
                                    )
                                    .foregroundStyle(selectedSlot == slot ? .white : Color.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                    } // end else (slots available)

                    Button {
                        guard let slot = selectedSlot else { return }
                        store.bookSession(staff: staff, date: slot)
                        withAnimation(.spring(response: 0.4)) {
                            confirmed = true
                        }
                    } label: {
                        Text("Confirm Booking")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedSlot != nil
                                          ? AnyShapeStyle(LinearGradient(colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                          : AnyShapeStyle(EPTheme.softText.opacity(0.3)))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedSlot == nil)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                Spacer()
            }
            .navigationTitle(staff.role == .coach ? "Book Session" : "Book Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
