// EditProfileView.swift
// EliteProAIDemo
//
// Editable profile form — updates local store immediately and syncs to backend.

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var buildingName: String = ""
    @State private var buildingOwner: String = ""
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar (tap to change – placeholder)
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(EPTheme.accent.opacity(0.18))
                                .frame(width: 90, height: 90)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(EPTheme.accent)
                            // Camera badge
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                                .background(Circle().fill(EPTheme.accent).frame(width: 28, height: 28))
                                .offset(x: 30, y: 30)
                        }
                        Text("Change Photo")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.accent)
                    }
                    .padding(.top, 8)

                    // Form fields
                    VStack(spacing: 16) {
                        editField(label: "Full Name", text: $name, contentType: .name)
                        editField(label: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                        editField(label: "Building", text: $buildingName, contentType: nil)
                        editField(label: "Management Company", text: $buildingOwner, contentType: nil)
                    }

                    if let error = AuthService.shared.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.red)
                    }

                    if showSaved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Saved!")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView().tint(EPTheme.accent)
                        } else {
                            Text("Save")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(hasChanges ? EPTheme.accent : EPTheme.softText)
                        }
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .onAppear {
                name = store.profile.name
                email = store.profile.email
                buildingName = store.profile.buildingName
                buildingOwner = store.profile.buildingOwner
            }
        }
    }

    private var hasChanges: Bool {
        name != store.profile.name ||
        email != store.profile.email ||
        buildingName != store.profile.buildingName ||
        buildingOwner != store.profile.buildingOwner
    }

    private func editField(label: String, text: Binding<String>, contentType: UITextContentType?, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(EPTheme.softText)
            TextField(label, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
        }
    }

    private func saveProfile() {
        isSaving = true

        // Update local store immediately for responsiveness
        store.profile.name = name.trimmingCharacters(in: .whitespaces)
        store.profile.email = email.trimmingCharacters(in: .whitespaces).lowercased()
        store.profile.buildingName = buildingName.trimmingCharacters(in: .whitespaces)
        store.profile.buildingOwner = buildingOwner.trimmingCharacters(in: .whitespaces)
        store.persist()

        // Sync to backend
        Task {
            let _ = await AuthService.shared.updateProfile(UpdateProfileRequest(
                name: store.profile.name,
                email: store.profile.email,
                buildingName: store.profile.buildingName,
                buildingOwner: store.profile.buildingOwner
            ))
            isSaving = false
            withAnimation { showSaved = true }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
}
