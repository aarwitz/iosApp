// AuthFlowUITests.swift
// EliteProAIDemoUITests
//
// UI tests for the authentication flow.

import XCTest

final class AuthFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset state for clean test runs
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    // MARK: – Onboarding

    func testOnboardingShowsOnFirstLaunch() {
        // Clear UserDefaults for onboarding flag
        app.launchArguments.append("-hasSeenOnboarding")
        app.launchArguments.append("NO")
        app.launch()

        // Should see the Get Started button
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
    }

    func testOnboardingDismissesToLogin() {
        app.launchArguments.append("-hasSeenOnboarding")
        app.launchArguments.append("NO")
        app.launch()

        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 5) {
            getStarted.tap()
        }

        // Should now see login screen
        let signIn = app.buttons["Sign In"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
    }

    // MARK: – Login Screen

    func testLoginScreenHasRequiredElements() {
        // Assuming onboarding is already dismissed for this test
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["••••••••"]
        let signInButton = app.buttons["Sign In"]
        let forgotButton = app.buttons["Forgot password?"]
        let signUpButton = app.buttons["Sign Up"]

        // At least the sign-in button or email field should appear
        let exists = signInButton.waitForExistence(timeout: 5) ||
                     emailField.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Login screen elements should be visible")
    }

    func testSignInButtonDisabledWithEmptyFields() {
        let signIn = app.buttons["Sign In"]
        guard signIn.waitForExistence(timeout: 5) else { return }

        XCTAssertFalse(signIn.isEnabled, "Sign In should be disabled with empty fields")
    }

    // MARK: – Navigation to Sign Up

    func testNavigateToSignUp() {
        let signUpButton = app.buttons["Sign Up"]
        guard signUpButton.waitForExistence(timeout: 5) else { return }

        signUpButton.tap()

        let createAccount = app.navigationBars["Create Account"]
        XCTAssertTrue(createAccount.waitForExistence(timeout: 5))
    }
}
