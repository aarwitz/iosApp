import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var viewMode: ViewMode = .week
    
    enum ViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    // Mock scheduled events
    private var scheduledEvents: [ScheduledEvent] {
        [
            ScheduledEvent(title: "1-on-1 Coaching", type: .coaching, time: Date().addingTimeInterval(3600), duration: 60, location: "Echelon Gym", trainer: "Jason Chen"),
            ScheduledEvent(title: "HIIT Class", type: .groupClass, time: Date().addingTimeInterval(7200), duration: 45, location: "Studio A", trainer: "Sarah Martinez"),
            ScheduledEvent(title: "Yoga Flow", type: .groupClass, time: Date().addingTimeInterval(86400 + 3600), duration: 60, location: "Studio B", trainer: "Maya Patel"),
            ScheduledEvent(title: "Nutrition Check-in", type: .nutrition, time: Date().addingTimeInterval(86400 * 2), duration: 30, location: "Virtual", trainer: "Priya Nair"),
            ScheduledEvent(title: "Group Run", type: .community, time: Date().addingTimeInterval(86400 * 3), duration: 45, location: "Seaport", trainer: nil),
            ScheduledEvent(title: "Strength Training", type: .coaching, time: Date().addingTimeInterval(86400 * 4), duration: 60, location: "Echelon Gym", trainer: "Andre Silva")
        ]
    }
    
    private var todayEvents: [ScheduledEvent] {
        scheduledEvents.filter { Calendar.current.isDate($0.time, inSameDayAs: selectedDate) }
    }
    
    private var upcomingEvents: [ScheduledEvent] {
        scheduledEvents.filter { $0.time > Date() }.sorted { $0.time < $1.time }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: – Header Card
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: 24))
                                .foregroundStyle(EPTheme.accent)
                            Text("My Schedule")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }
                        
                        Text("Manage your fitness activities, classes, and coaching sessions.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
                
                // MARK: – View Mode Picker
                HStack(spacing: 0) {
                    ForEach(ViewMode.allCases, id: \.rawValue) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewMode = mode
                            }
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(.subheadline, design: .rounded).weight(viewMode == mode ? .bold : .regular))
                                .foregroundStyle(viewMode == mode ? Color.primary : EPTheme.softText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(viewMode == mode ? EPTheme.accent.opacity(0.25) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
                
                // MARK: – Quick Stats
                HStack(spacing: 12) {
                    statCard(icon: "calendar.badge.clock", value: "\(upcomingEvents.count)", label: "Upcoming")
                    statCard(icon: "checkmark.circle.fill", value: "12", label: "Completed")
                    statCard(icon: "clock.fill", value: "8.5h", label: "This Week")
                }
                
                // MARK: – Today's Schedule
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today")
                            .font(.system(.headline, design: .rounded))
                        Spacer()
                        Text(selectedDate, style: .date)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    
                    if todayEvents.isEmpty {
                        EPCard {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(EPTheme.softText)
                                Text("No events scheduled for today")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                                
                                Button {
                                    // Add event action
                                } label: {
                                    Text("Book a Session")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(EPTheme.accent)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    } else {
                        ForEach(todayEvents) { event in
                            eventCard(event)
                        }
                    }
                }
                
                // MARK: – Upcoming Events
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming")
                        .font(.system(.headline, design: .rounded))
                    
                    ForEach(upcomingEvents.filter { !Calendar.current.isDate($0.time, inSameDayAs: selectedDate) }) { event in
                        eventCard(event)
                    }
                }
                
                // MARK: – Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(.headline, design: .rounded))
                    
                    HStack(spacing: 12) {
                        NavigationLink {
                            CoachingView()
                        } label: {
                            quickActionButton(icon: "person.fill", title: "Book Coach", color: .blue)
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            GroupClassView()
                        } label: {
                            quickActionButton(icon: "figure.run", title: "Join Class", color: .green)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 12) {
                        NavigationLink {
                            NutritionView()
                        } label: {
                            quickActionButton(icon: "leaf.fill", title: "Nutrition", color: .orange)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            // View all activities
                        } label: {
                            quickActionButton(icon: "calendar.badge.plus", title: "View All", color: .purple)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Schedule")
                    .font(.system(.headline, design: .rounded))
            }
        }
    }
    
    // MARK: – Stat Card
    
    private func statCard(icon: String, value: String, label: String) -> some View {
        EPCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(EPTheme.accent)
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: – Event Card
    
    private func eventCard(_ event: ScheduledEvent) -> some View {
        EPCard {
            HStack(spacing: 12) {
                // Time indicator
                VStack(spacing: 2) {
                    Text(event.time, style: .time)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                    Text("\(event.duration)m")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                .frame(width: 55)
                
                // Type indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(event.type.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: event.type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(event.type.color)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                        Text(event.location)
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(EPTheme.softText)
                    
                    if let trainer = event.trainer {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 10))
                            Text(trainer)
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(EPTheme.accent)
                    }
                }
                
                Spacer()
                
                // Action button
                Button {
                    // Event action
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(EPTheme.softText)
                        .padding(8)
                        .background(Circle().fill(EPTheme.card))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: – Quick Action Button
    
    private func quickActionButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – Supporting Types

struct ScheduledEvent: Identifiable {
    let id = UUID()
    let title: String
    let type: EventType
    let time: Date
    let duration: Int  // minutes
    let location: String
    let trainer: String?
    
    enum EventType {
        case coaching
        case groupClass
        case nutrition
        case community
        
        var icon: String {
            switch self {
            case .coaching: return "person.fill"
            case .groupClass: return "figure.run"
            case .nutrition: return "leaf.fill"
            case .community: return "person.3.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .coaching: return .blue
            case .groupClass: return .green
            case .nutrition: return .orange
            case .community: return .purple
            }
        }
    }
}
