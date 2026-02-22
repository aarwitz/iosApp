// ChangePasswordView.swift
// EliteProAIDemo
//
// Authenticated password change form with validation.

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Password")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(EPTheme.softText)
                    SecureField("Enter current password", text: $currentPassword)
                        .textContentType(.password)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("New Password")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(EPTheme.softText)
                    SecureField("At least 8 characters", text: $newPassword)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm New Password")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(EPTheme.softText)
                    SecureField("Re-enter new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                            !confirmPassword.isEmpty && confirmPassword != newPassword ? Color.red.opacity(0.6) : EPTheme.cardStroke,
                            lineWidth: 1
                        ))

                    if !confirmPassword.isEmpty && confirmPassword != newPassword {
                        Text("Passwords don't match")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.red)
                }

                if showSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Password updated!")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    changePassword()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Password")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(formValid ? EPTheme.accent : EPTheme.accent.opacity(0.4))
                    )
                }
                .disabled(!formValid || isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword &&
        newPassword != currentPassword
    }

    private func changePassword() {
        isLoading = true
        Task {
            let success = await auth.changePassword(current: currentPassword, new: newPassword)
            isLoading = false
            if success {
                withAnimation { showSuccess = true }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        }
    }
}
