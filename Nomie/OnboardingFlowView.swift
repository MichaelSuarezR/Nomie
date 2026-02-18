//
//  OnboardingFlowView.swift
//  Nomie
//

import SwiftUI
import Supabase
import UIKit

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pageIndex = 0
    @State private var selectedGoals: Set<String> = []
    @State private var authMode: AuthView.Mode = .signUp
    @State private var showLoginSheet = false
    @State private var showSignUpSheet = false
    private let totalPages = 4

    var body: some View {
        let isAuthed = appState.session != nil
        let isAuthSheetVisible = showLoginSheet || showSignUpSheet
        let backgroundStyle: OnboardingWelcomeBackground.Style = showLoginSheet
            ? .login
            : (showSignUpSheet ? .signup : .welcome)

        ZStack {
            if pageIndex == 0 {
                OnboardingWelcomeBackground(style: backgroundStyle)
            } else if pageIndex == 2 {
                OnboardingWelcomeBackground(style: .goals)
            } else if pageIndex == 3 {
                OnboardingWelcomeBackground(style: .tracking)
            } else {
                Color.white.ignoresSafeArea()
            }

            VStack(spacing: 0) {
            OnboardingTopBar(
                canGoBack: pageIndex > 0,
                showsSkip: isAuthed && pageIndex > 1,
                onBack: { pageIndex = max(0, pageIndex - 1) },
                onSkip: completeOnboarding
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Group {
                switch pageIndex {
                case 0:
                    OnboardingWelcomeView(
                        isAuthSheetVisible: isAuthSheetVisible,
                        onSignUp: {
                            appState.resetOnboarding()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showSignUpSheet = true
                            }
                        },
                        onLogIn: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showLoginSheet = true
                            }
                        }
                    )
                case 1:
                    AuthView(initialMode: authMode)
                        .id(authMode)
                case 2:
                    OnboardingGoalsView(selectedGoals: $selectedGoals)
                default:
                    OnboardingTrackingView()
                }
            }

            if pageIndex > 1 {
                OnboardingPageIndicator(
                    currentIndex: max(0, pageIndex - 2),
                    total: max(1, totalPages - 2)
                )
                .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 18)
            }

            if pageIndex > 1 {
                Button(action: advance) {
                    Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            } else {
                Spacer().frame(height: 44)
            }
            }

            if pageIndex == 0, showLoginSheet {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    LoginSheetView(
                        onClose: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showLoginSheet = false
                            }
                        },
                        onSignUp: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showLoginSheet = false
                                appState.resetOnboarding()
                                showSignUpSheet = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }

            if pageIndex == 0, showSignUpSheet {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    SignUpSheetView(
                        onClose: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showSignUpSheet = false
                            }
                        },
                        onLogIn: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showSignUpSheet = false
                                showLoginSheet = true
                            }
                        },
                        onSuccess: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showSignUpSheet = false
                                pageIndex = 2
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onChange(of: pageIndex) { newValue in
            if newValue > 1 && appState.session == nil {
                pageIndex = 1
            }
        }
        .onChange(of: appState.session?.user.id) { _ in
            if appState.session != nil {
                if showLoginSheet || showSignUpSheet {
                    showLoginSheet = false
                    showSignUpSheet = false
                    pageIndex = 2
                } else if pageIndex == 1 {
                    pageIndex = 2
                }
            }
        }
    }

    private func advance() {
        if pageIndex == 0 && appState.session == nil {
            pageIndex = 1
            return
        }

        if pageIndex == 1 && appState.session == nil {
            return
        }

        if pageIndex < totalPages - 1 {
            pageIndex += 1
        } else {
            saveGoals()
            completeOnboarding()
        }
    }

    private func saveGoals() {
        let goals = Array(selectedGoals)
        UserDefaults.standard.set(goals, forKey: "selectedGoals")
    }

    private func completeOnboarding() {
        saveGoals()
        appState.completeOnboarding()
    }
}

private struct OnboardingTopBar: View {
    let canGoBack: Bool
    let showsSkip: Bool
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(canGoBack ? .black : .clear)
            }
            .disabled(!canGoBack)

            Spacer()

            if showsSkip {
                Button("Skip", action: onSkip)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct OnboardingPageIndicator: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.black.opacity(0.65) : Color.black.opacity(0.25))
                    .frame(width: index == currentIndex ? 30 : 22, height: 3)
            }
        }
    }
}

private struct OnboardingWelcomeView: View {
    let isAuthSheetVisible: Bool
    let onSignUp: () -> Void
    let onLogIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.77, blue: 0.62),
                                    Color(red: 0.95, green: 0.52, blue: 0.58),
                                    Color(red: 0.87, green: 0.36, blue: 0.46)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 18
                            )
                        )
                        .frame(width: 16, height: 16)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                    Text("NOMIE")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.black.opacity(0.75))
                        .tracking(1.5)
                }
            }
            .opacity(isAuthSheetVisible ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: isAuthSheetVisible)
            .padding(.horizontal, 28)
            .padding(.top, 5)

            Spacer(minLength: 500)

            VStack(alignment: .leading, spacing: 8) {
                Text("Hello")
                    .font(.system(size: 44, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(Color.black.opacity(0.75))
                Text("Ready to unlock your zine?")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(Color.black.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer(minLength: 100)

            VStack(spacing: 12) {
                Button(action: onSignUp) {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.7))
                        .foregroundColor(Color.black.opacity(0.75))
                        .overlay(
                            Capsule().stroke(Color.black.opacity(0.55), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }

                Button(action: onLogIn) {
                    Text("Log In")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(Color.black.opacity(0.7))
                        .overlay(
                            Capsule().stroke(Color.black.opacity(0.55), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingWelcomeBackground: View {
    enum Style {
        case welcome
        case login
        case signup
        case goals
        case tracking
    }

    let style: Style

    var body: some View {
        ZStack {
            if style == .welcome {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.95, blue: 0.82),
                        Color(red: 0.99, green: 0.82, blue: 0.70),
                        Color(red: 0.98, green: 0.70, blue: 0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if style == .login {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.92, blue: 0.78),
                        Color(red: 0.76, green: 0.90, blue: 0.80),
                        Color(red: 0.60, green: 0.86, blue: 0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if style == .goals {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.80, blue: 0.70),
                        Color(red: 0.80, green: 0.84, blue: 0.70),
                        Color(red: 0.52, green: 0.80, blue: 0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if style == .tracking {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.78, blue: 0.62),
                        Color(red: 0.95, green: 0.70, blue: 0.62),
                        Color(red: 0.92, green: 0.60, blue: 0.58)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.83, blue: 0.70),
                        Color(red: 0.97, green: 0.67, blue: 0.58),
                        Color(red: 0.94, green: 0.53, blue: 0.52)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            RadialGradient(
                colors: [
                    style == .welcome
                    ? Color(red: 0.94, green: 0.54, blue: 0.64).opacity(0.95)
                    : (style == .login
                       ? Color(red: 0.62, green: 0.86, blue: 0.85).opacity(0.95)
                       : style == .goals
                       ? Color(red: 0.70, green: 0.86, blue: 0.80).opacity(0.92)
                       : style == .tracking
                       ? Color(red: 0.98, green: 0.82, blue: 0.66).opacity(0.92)
                       : Color(red: 0.99, green: 0.84, blue: 0.72).opacity(0.92)),
                    style == .welcome
                    ? Color(red: 0.97, green: 0.74, blue: 0.66).opacity(0.9)
                    : (style == .login
                       ? Color(red: 0.84, green: 0.88, blue: 0.74).opacity(0.9)
                       : style == .goals
                       ? Color(red: 0.86, green: 0.84, blue: 0.62).opacity(0.88)
                       : style == .tracking
                       ? Color(red: 0.98, green: 0.70, blue: 0.56).opacity(0.88)
                       : Color(red: 0.96, green: 0.70, blue: 0.58).opacity(0.88)),
                    style == .welcome
                    ? Color(red: 0.99, green: 0.92, blue: 0.78).opacity(0.9)
                    : (style == .login
                       ? Color(red: 0.94, green: 0.78, blue: 0.62).opacity(0.88)
                       : style == .goals
                       ? Color(red: 0.52, green: 0.80, blue: 0.78).opacity(0.9)
                       : style == .tracking
                       ? Color(red: 0.98, green: 0.60, blue: 0.56).opacity(0.9)
                       : Color(red: 0.94, green: 0.52, blue: 0.52).opacity(0.9))
                ],
                center: UnitPoint(x: 0.78, y: 0.45),
                startRadius: 60,
                endRadius: 420
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.5),
                    Color.clear,
                    Color.white.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

private struct LoginSheetView: View {
    let onClose: () -> Void
    let onSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isLoading = false
    @State private var message: String?
    @State private var keyboardHeight: CGFloat = 0

    private let supabase = SupabaseManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 48, height: 6)

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(Color.black.opacity(0.8))
                    Text("Ready to continue?")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color.black.opacity(0.65))
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                            )
                    }

                    HStack {
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(.black.opacity(0.7))
                                Text("Remember Me")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black.opacity(0.75))
                            }
                        }

                        Spacer()

                        Button("Forgot Password") {
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 30)

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button(action: submit) {
                    Text(isLoading ? "Please wait..." : "Log In")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(Color.black.opacity(0.75))
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.74, green: 0.88, blue: 0.84),
                                    Color(red: 0.92, green: 0.86, blue: 0.62)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                }
                .disabled(isLoading || !canSubmit)
                .padding(.horizontal, 30)
                .padding(.top, 8)

                Button(action: onSignUp) {
                    Text("Don’t have an account? ")
                        .foregroundColor(.black.opacity(0.65))
                    + Text("Sign up")
                        .foregroundColor(.black.opacity(0.9))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .padding(.bottom, 22)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: 620)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
        .padding(.horizontal, 16)
        .padding(.bottom, 20 + keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear { keyboardHeight = 0 }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            let screenHeight = UIScreen.main.bounds.height
            let overlap = max(0, screenHeight - endFrame.origin.y)
            keyboardHeight = overlap > 0 ? overlap : 0
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private func submit() {
        message = nil
        isLoading = true

        Task {
            do {
                try await supabase.auth.signIn(email: email, password: password)
            } catch {
                message = error.localizedDescription
            }
            isLoading = false
        }
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedEmail.isEmpty && !password.isEmpty
    }
}

private struct SignUpSheetView: View {
    let onClose: () -> Void
    let onLogIn: () -> Void
    let onSuccess: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message: String?
    @State private var keyboardHeight: CGFloat = 0

    private let supabase = SupabaseManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 48, height: 6)

                VStack(spacing: 6) {
                    Text("Create your account")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(Color.black.opacity(0.8))
                    Text("Sign up to get started")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color.black.opacity(0.65))
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                        HStack(spacing: 10) {
                        TextField("", text: $firstName, prompt: Text("First").foregroundColor(.gray))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                        TextField("", text: $lastName, prompt: Text("Last").foregroundColor(.gray))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.gray))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button(action: submit) {
                    Text(isLoading ? "Please wait..." : "Sign Up")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(Color.black.opacity(0.75))
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.83, blue: 0.73),
                                    Color(red: 0.96, green: 0.74, blue: 0.56)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                }
                .disabled(isLoading || !canSubmit)
                .padding(.horizontal, 30)
                .padding(.top, 6)

                Button(action: onLogIn) {
                    Text("Already have an account? ")
                        .foregroundColor(.black.opacity(0.65))
                    + Text("Log In")
                        .foregroundColor(.black.opacity(0.9))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .padding(.bottom, 22)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: 680)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
        .padding(.horizontal, 16)
        .padding(.bottom, 20 + keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .onAppear { keyboardHeight = 0 }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            let screenHeight = UIScreen.main.bounds.height
            let overlap = max(0, screenHeight - endFrame.origin.y)
            keyboardHeight = overlap > 0 ? overlap : 0
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private func submit() {
        message = nil
        isLoading = true

        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

                guard password == confirmPassword else {
                    message = "Passwords do not match."
                    isLoading = false
                    return
                }

                guard !trimmedFirst.isEmpty, !trimmedLast.isEmpty else {
                    message = "Please enter your first and last name."
                    isLoading = false
                    return
                }

                let response = try await supabase.auth.signUp(
                    email: trimmedEmail,
                    password: password,
                    data: [
                        "first_name": .string(trimmedFirst),
                        "last_name": .string(trimmedLast)
                    ]
                )

                let user = response.user
                let profile = OnboardingProfileInsert(
                    id: user.id,
                    email: trimmedEmail,
                    first_name: trimmedFirst,
                    last_name: trimmedLast
                )
                try await supabase.database
                    .from("profiles")
                    .insert(profile)
                    .execute()

                await MainActor.run {
                    onSuccess()
                }
            } catch {
                message = error.localizedDescription
            }
            isLoading = false
        }
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !firstName.isEmpty &&
            !lastName.isEmpty &&
            !trimmedEmail.isEmpty &&
            !password.isEmpty &&
            !confirmPassword.isEmpty
    }
}

private struct OnboardingProfileInsert: Encodable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
}


private struct MoodCloudView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let bubbleSize = width * 0.34
            let rowSpacing = width * 0.07
            let edgeBuffer = bubbleSize * 0.9

            VStack(spacing: rowSpacing) {
                MoodRow(
                    images: ["Illustration294 1", "Illustration295 1", "Illustration296 1"],
                    bubbleSize: bubbleSize,
                    direction: -1,
                    horizontalOffset: -width * 0.06,
                    edgeBuffer: edgeBuffer,
                    speed: 18,
                    extraRepeats: 2,
                    rowWidth: width,
                    floatPhase: 0
                )
                MoodRow(
                    images: ["Illustration297 1", "Illustration298 1", "Illustration299 1"],
                    bubbleSize: bubbleSize,
                    direction: 1,
                    horizontalOffset: width * 0.04,
                    edgeBuffer: edgeBuffer,
                    speed: 16,
                    extraRepeats: 2,
                    rowWidth: width,
                    floatPhase: 2.1
                )
                MoodRow(
                    images: ["Illustration300 1", "Illustration301 1", "Illustration302 1"],
                    bubbleSize: bubbleSize,
                    direction: -1,
                    horizontalOffset: -width * 0.06,
                    edgeBuffer: edgeBuffer,
                    speed: 20,
                    extraRepeats: 4,
                    rowWidth: width,
                    floatPhase: 4.2
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct MoodRow: View {
    let images: [String]
    let bubbleSize: CGFloat
    let direction: CGFloat
    let horizontalOffset: CGFloat
    let edgeBuffer: CGFloat
    let speed: CGFloat
    let extraRepeats: Int
    let rowWidth: CGFloat
    let floatPhase: CGFloat

    init(
        images: [String],
        bubbleSize: CGFloat,
        direction: CGFloat,
        horizontalOffset: CGFloat,
        edgeBuffer: CGFloat,
        speed: CGFloat,
        extraRepeats: Int = 0,
        rowWidth: CGFloat,
        floatPhase: CGFloat = 0
    ) {
        self.images = images
        self.bubbleSize = bubbleSize
        self.direction = direction
        self.horizontalOffset = horizontalOffset
        self.edgeBuffer = edgeBuffer
        self.speed = speed
        self.extraRepeats = extraRepeats
        self.rowWidth = rowWidth
        self.floatPhase = floatPhase
    }

    var body: some View {
        TimelineView(.animation) { context in
            let cycle = bubbleSize * CGFloat(images.count)
            let repeats = max(6, Int(ceil((rowWidth + edgeBuffer * 2 + cycle) / cycle))) + 2 + extraRepeats
            let totalWidth = cycle * CGFloat(repeats)
            let t = context.date.timeIntervalSinceReferenceDate
            let raw = CGFloat(t) * speed
            let normalized = (raw.truncatingRemainder(dividingBy: cycle) + cycle)
                .truncatingRemainder(dividingBy: cycle)
            let offset = direction < 0 ? -normalized : normalized
            let floatAmplitude = bubbleSize * 0.06
            let float = sin(CGFloat(t) * 0.45 + floatPhase) * floatAmplitude

            HStack(spacing: 0) {
                ForEach(0..<repeats, id: \.self) { _ in
                    ForEach(Array(images.enumerated()), id: \.offset) { index, name in
                        let phase = floatPhase + CGFloat(index) * 1.4
                        let localFloat = sin(CGFloat(t) * 0.45 + phase) * floatAmplitude

                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: bubbleSize, height: bubbleSize)
                            .offset(y: localFloat)
                    }
                }
            }
            .frame(width: totalWidth, alignment: .leading)
            .offset(x: horizontalOffset - edgeBuffer + offset - cycle)
            .frame(width: rowWidth, height: bubbleSize + floatAmplitude * 2, alignment: .leading)
            .clipped()
        }
        .frame(width: rowWidth, height: bubbleSize + bubbleSize * 0.08, alignment: .leading)
    }
}

private struct OnboardingGoalsView: View {
    @Binding var selectedGoals: Set<String>

    private let goals = [
        "Reduce doomscrolling",
        "Stay present",
        "Reflect daily",
        "Build focus"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What are your goals?")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color.black.opacity(0.75))
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                ForEach(goals, id: \.self) { goal in
                    GoalButton(title: goal, isSelected: selectedGoals.contains(goal)) {
                        toggle(goal)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 40)
    }

    private func toggle(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
}

private struct GoalButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(isSelected ? 0.95 : 0.85))
                .foregroundColor(Color.black.opacity(0.75))
                .overlay(
                    Capsule().stroke(Color.black.opacity(0.45), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
}

private struct OnboardingTrackingView: View {
    @State private var selections: [String: Bool] = [
        "Category 1": true,
        "Lorem Ipsum": true,
        "Lorem Ipsum 2": true,
        "Lorem Ipsum 3": true
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Allow us to track?")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color.black.opacity(0.75))
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                ForEach(selections.keys.sorted(), id: \.self) { key in
                    TrackingRow(
                        title: key,
                        isOn: Binding(
                            get: { selections[key] ?? false },
                            set: { selections[key] = $0 }
                        )
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 40)
    }
}

private struct TrackingRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.9))
                .foregroundColor(Color.black.opacity(0.75))
                .overlay(
                    Capsule().stroke(Color.black.opacity(0.45), lineWidth: 1)
                )
                .clipShape(Capsule())

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.62, green: 0.90, blue: 0.76))
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState())
}
