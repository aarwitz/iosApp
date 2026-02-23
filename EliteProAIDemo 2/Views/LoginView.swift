// LoginView.swift
// EliteProAIDemo
//
// Email + password login screen with "Forgot Password" support.

import SwiftUI

struct LoginView: View {
    @ObservedObject private var auth = AuthService.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    @State private var forgotEmail = ""
    @State private var forgotSent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Logo / Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(EPTheme.accent)
                    }

                    Text("Elite Pro AI")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Text("Sign in to continue")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                .padding(.top, 40)

                // Form fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.softText)
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.softText)
                        SecureField("••••••••", text: $password)
                            .textContentType(.password)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                    }

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            forgotEmail = email
                            showForgotPassword = true
                        }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.accent)
                    }
                }

                // Error
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // Login button
                Button {
                    performLogin()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Sign In")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(formValid ? EPTheme.accent : EPTheme.accent.opacity(0.4))
                )
                .disabled(!formValid || isLoading)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(EPTheme.divider)
                    Text("or")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                    Rectangle().frame(height: 1).foregroundStyle(EPTheme.divider)
                }

                // Social login placeholders
                VStack(spacing: 12) {
                    socialButton(icon: "apple.logo", label: "Continue with Apple", bg: Color.primary, fg: Color(white: 1.0))
                    socialButton(icon: "g.circle.fill", label: "Continue with Google", bg: EPTheme.card, fg: .primary)
                }

                // Sign up link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(EPTheme.accent)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    // MARK: – Helpers

    private var formValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6
    }

    private func performLogin() {
        isLoading = true
        Task {
            let _ = await auth.login(email: email.trimmingCharacters(in: .whitespaces).lowercased(), password: password)
            isLoading = false
        }
    }

    private func socialButton(icon: String, label: String, bg: Color, fg: Color) -> some View {
        Button {
            // TODO: Implement social auth
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
        }
    }

    // MARK: – Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if forgotSent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(EPTheme.accent)
                        Text("Check your inbox")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Text("We sent a password reset link to **\(forgotEmail)**.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Enter your email and we'll send a reset link.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                        TextField("Email address", text: $forgotEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                    }
                    .padding(.top, 20)

                    Button {
                        Task {
                            let success = await auth.forgotPassword(email: forgotEmail)
                            if success { forgotSent = true }
                        }
                    } label: {
                        Text("Send Reset Link")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(EPTheme.accent))
                    }
                    .disabled(forgotEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showForgotPassword = false
                        forgotSent = false
                    }
                }
            }
        }
    }
}
