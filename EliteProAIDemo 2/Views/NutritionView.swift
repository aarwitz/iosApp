import SwiftUI

struct NutritionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var notes: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nutrition Check-In")
                            .font(.system(.headline, design: .rounded))
                        TextField("Calories (e.g. 2100)", text: $calories)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Protein g (e.g. 150)", text: $protein)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            store.earnCredits(5)
                        } label: {
                            Text("Submit (Demo)")
                        }
                        .buttonStyle(EPButtonStyle())

                        Text("Submitting earns credits in this demo.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }
}
