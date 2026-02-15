import SwiftUI

struct HabitsTrackerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var sleep: Bool = true
    @State private var water: Bool = false
    @State private var steps: Bool = true
    @State private var lift: Bool = false

    var body: some View {
        List {
            Section("Today") {
                Toggle("8h Sleep", isOn: $sleep)
                Toggle("2L Water", isOn: $water)
                Toggle("8k Steps", isOn: $steps)
                Toggle("Workout", isOn: $lift)
            }

            Section {
                Button("Mark Complete (Demo)") {
                    let count = [sleep, water, steps, lift].filter { $0 }.count
                    store.earnCredits(count * 2)
                }
                .tint(EPTheme.accent)
            } footer: {
                Text("This demo awards credits based on how many habits are checked.")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Habits Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
}
