// SignUpView.swift
// EliteProAIDemo
//
// Multi-step sign-up flow: credentials → building selection → confirmation.

import SwiftUI

struct SignUpView: View {
    @ObservedObject private var auth = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    // Step management
    @State private var step: SignUpStep = .credentials

    // Step 1: credentials
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Step 2: building selection
    @State private var buildingName = ""
    @State private var buildingOwner = ""
    @State private var selectedBuilding: BuildingOption?

    @State private var isLoading = false
    @State private var agreedToTerms = false

    enum SignUpStep: Int, CaseIterable {
        case credentials = 0
        case building = 1
        case review = 2
    }

    // Pre-populated building options for the Seaport demo
    private let buildingOptions: [BuildingOption] = [
        BuildingOption(name: "Echelon Seaport", owner: "Barkan Management"),
        BuildingOption(name: "Via Seaport", owner: "The Fallon Company"),
        BuildingOption(name: "Watermark Seaport", owner: "Greystar"),
        BuildingOption(name: "One Seaport", owner: "WS Development"),
        BuildingOption(name: "50 Liberty", owner: "Hines"),
        BuildingOption(name: "The Clarendon", owner: "Trinity Place Holdings"),
        BuildingOption(name: "Troy Boston", owner: "Samuels & Associates")
    ]

    struct BuildingOption: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let owner: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress indicator
                    progressBar

                    switch step {
                    case .credentials:  credentialsStep
                    case .building:     buildingStep
                    case .review:       reviewStep
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if step == .credentials {
                            dismiss()
                        } else {
                            withAnimation { step = SignUpStep(rawValue: step.rawValue - 1)! }
                        }
                    } label: {
                        Image(systemName: step == .credentials ? "xmark" : "chevron.left")
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case .credentials: return "Create Account"
        case .building:    return "Your Building"
        case .review:      return "Review"
        }
    }

    // MARK: – Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(SignUpStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? EPTheme.accent : EPTheme.divider)
                    .frame(height: 4)
            }
        }
    }

    // MARK: – Step 1: Credentials

    private var credentialsStep: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(EPTheme.softText)
                TextField("Jamie Smith", text: $name)
                    .textContentType(.name)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
            }

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
                SecureField("At least 8 characters", text: $password)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))

                passwordStrengthIndicator
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(EPTheme.softText)
                SecureField("Re-enter password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        !confirmPassword.isEmpty && confirmPassword != password ? Color.red.opacity(0.6) : EPTheme.cardStroke,
                        lineWidth: 1
                    ))

                if !confirmPassword.isEmpty && confirmPassword != password {
                    Text("Passwords don't match")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.red)
                }
            }

            Button {
                withAnimation { step = .building }
            } label: {
                Text("Continue")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(credentialsValid ? EPTheme.accent : EPTheme.accent.opacity(0.4))
                    )
            }
            .disabled(!credentialsValid)
        }
    }

    private var credentialsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private var passwordStrengthIndicator: some View {
        let strength = passwordStrength
        return HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i < strength.level ? strength.color : EPTheme.divider)
                    .frame(height: 3)
            }
            Text(strength.label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(strength.color)
        }
    }

    private var passwordStrength: (level: Int, label: String, color: Color) {
        let p = password
        if p.count < 6  { return (0, "", .clear) }
        if p.count < 8  { return (1, "Weak", .red) }
        let hasUpper = p.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasDigit = p.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = p.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let score = [hasUpper, hasDigit, hasSpecial].filter(\.self).count
        switch score {
        case 0: return (1, "Weak", .red)
        case 1: return (2, "Fair", .orange)
        case 2: return (3, "Good", .yellow)
        default: return (4, "Strong", .green)
        }
    }

    // MARK: – Step 2: Building

    private var buildingStep: some View {
        VStack(spacing: 18) {
            Text("Select your building so we can connect you with your neighbors.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(buildingOptions) { option in
                    Button {
                        selectedBuilding = option
                        buildingName = option.name
                        buildingOwner = option.owner
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(selectedBuilding == option ? .white : EPTheme.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                Text(option.owner)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(selectedBuilding == option ? .white.opacity(0.7) : EPTheme.softText)
                            }
                            Spacer()
                            if selectedBuilding == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .foregroundStyle(selectedBuilding == option ? .white : .primary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedBuilding == option ? EPTheme.accent : EPTheme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedBuilding == option ? EPTheme.accent : EPTheme.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Manual entry option
            VStack(alignment: .leading, spacing: 6) {
                Text("Not listed? Enter manually:")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                TextField("Building name", text: $buildingName)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(EPTheme.cardStroke, lineWidth: 1))
                    .onChange(of: buildingName) { _ in
                        if buildingOptions.first(where: { $0.name == buildingName }) == nil {
                            selectedBuilding = nil
                        }
                    }
            }

            Button {
                withAnimation { step = .review }
            } label: {
                Text("Continue")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!buildingName.isEmpty ? EPTheme.accent : EPTheme.accent.opacity(0.4))
                    )
            }
            .disabled(buildingName.isEmpty)
        }
    }

    // MARK: – Step 3: Review & Submit

    private var reviewStep: some View {
        VStack(spacing: 20) {
            EPCard {
                VStack(alignment: .leading, spacing: 12) {
                    reviewRow(label: "Name", value: name)
                    Divider().overlay(EPTheme.divider)
                    reviewRow(label: "Email", value: email)
                    Divider().overlay(EPTheme.divider)
                    reviewRow(label: "Building", value: buildingName)
                    if !buildingOwner.isEmpty {
                        Divider().overlay(EPTheme.divider)
                        reviewRow(label: "Management", value: buildingOwner)
                    }
                }
            }

            Toggle(isOn: $agreedToTerms) {
                Text("I agree to the [Terms of Service](https://eliteproai.com/terms) and [Privacy Policy](https://eliteproai.com/privacy)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
            .tint(EPTheme.accent)

            if let error = auth.errorMessage {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.red)
            }

            Button {
                performSignUp()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Create Account")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(agreedToTerms ? EPTheme.accent : EPTheme.accent.opacity(0.4))
            )
            .disabled(!agreedToTerms || isLoading)
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(EPTheme.softText)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
        }
    }

    private func performSignUp() {
        isLoading = true
        Task {
            let _ = await auth.signUp(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                buildingName: buildingName,
                buildingOwner: buildingOwner
            )
            isLoading = false
        }
    }
}
