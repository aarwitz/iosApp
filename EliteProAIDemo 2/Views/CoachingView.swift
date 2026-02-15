import SwiftUI

struct CoachingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTrainer: Trainer?
    @State private var date = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Pick a trainer")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(EPTheme.softText)

                ForEach(store.trainers) { t in
                    Button {
                        selectedTrainer = t
                    } label: {
                        EPCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(t.name)
                                        .font(.system(.headline, design: .rounded))
                                    Text(t.specialty)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                    Text("⭐️ \(String(format: "%.1f", t.rating)) · $\(t.pricePerSession)/session")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                }
                                Spacer()
                                Image(systemName: selectedTrainer?.id == t.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedTrainer?.id == t.id ? EPTheme.accent : EPTheme.softText)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("When?")
                            .font(.system(.headline, design: .rounded))
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .tint(EPTheme.accent)

                        Button {
                            // demo: reward credits for scheduling
                            store.earnCredits(10)
                        } label: {
                            Text("Schedule (Demo)")
                        }
                        .buttonStyle(EPButtonStyle())
                        .disabled(selectedTrainer == nil)
                        .opacity(selectedTrainer == nil ? 0.5 : 1.0)

                        Text("Scheduling earns credits in this demo.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("1–1 Coaching")
        .navigationBarTitleDisplayMode(.inline)
    }
}
