import SwiftUI

struct ConnectorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search: String = ""

    var filtered: [Trainer] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.trainers }
        return store.trainers.filter { $0.name.lowercased().contains(q) || $0.specialty.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Find a trainer")
                            .font(.system(.headline, design: .rounded))
                        TextField("Search specialty or name", text: $search)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                ForEach(filtered) { t in
                    EPCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t.name).font(.system(.headline, design: .rounded))
                                Text(t.specialty).font(.system(.subheadline, design: .rounded)).foregroundStyle(EPTheme.softText)
                                Text("⭐️ \(String(format: "%.1f", t.rating)) · $\(t.pricePerSession)/session")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            NavigationLink {
                                TrainerDetailView(trainer: t)
                            } label: {
                                Text("View")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(EPTheme.accent.opacity(0.18)))
                                    .overlay(Capsule().stroke(EPTheme.accent.opacity(0.55), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Connector")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrainerDetailView: View {
    @EnvironmentObject private var store: AppStore
    let trainer: Trainer
    @State private var note: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trainer.name).font(.system(.title3, design: .rounded).weight(.semibold))
                        Text(trainer.specialty).foregroundStyle(EPTheme.softText)
                        Text("⭐️ \(String(format: "%.1f", trainer.rating)) · $\(trainer.pricePerSession)/session")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message")
                            .font(.system(.headline, design: .rounded))
                        TextField("What do you want to work on?", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            store.addChatMessage(text: "Hi \(trainer.name) — \(note.isEmpty ? "I'd like to chat about coaching." : note)")
                            store.earnCredits(2)
                            note = ""
                        } label: {
                            Text("Send (Demo)")
                        }
                        .buttonStyle(EPButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Trainer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
