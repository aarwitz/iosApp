import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject private var store: AppStore
    @State private var workout: String = ""
    @State private var saved: [String] = ["Upper 45m · Bench 3x5 · Rows 3x10", "Run 25m · Easy pace"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Workout Log")
                            .font(.system(.headline, design: .rounded))

                        TextField("Add a workout (e.g. Squat 3x5)", text: $workout)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            let t = workout.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            saved.insert(t, at: 0)
                            workout = ""
                            store.earnCredits(3)
                        } label: { Text("Save (Demo)") }
                        .buttonStyle(EPButtonStyle())

                        Divider().overlay(EPTheme.divider)

                        ForEach(saved, id: \.self) { item in
                            Text("• \(item)")
                                .foregroundStyle(Color.primary.opacity(0.9))
                                .font(.system(.subheadline, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}
