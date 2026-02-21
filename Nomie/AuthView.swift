//
//  AuthView.swift
//  Nomie
//

import SwiftUI
import Supabase

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("usesMockAccount") private var usesMockAccount = false

    enum Mode {
        case signUp
        case logIn
    }

    @State private var mode: Mode
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var useMockAccount = false
    @State private var isLoading = false
    @State private var message: String?

    private let supabase = SupabaseManager.shared

    init(initialMode: Mode = .signUp) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            if mode == .signUp {
                SignUpBackground()
            } else {
                Color.white.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                if mode == .signUp {
                    SignUpCard(
                        firstName: $firstName,
                        lastName: $lastName,
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        useMockAccount: $useMockAccount,
                        isLoading: isLoading,
                        message: message,
                        canSubmit: canSubmit,
                        onSubmit: submit,
                        onToggleMode: toggleMode
                    )
                } else {
                    VStack(spacing: 20) {
                        Text("Welcome back")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        VStack(spacing: 14) {
                            TextField("Email", text: $email, prompt: Text("Email").foregroundColor(.gray))
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 28)

                        if let message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }

                        Button(action: submit) {
                            Text(isLoading ? "Please wait..." : "Log In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .disabled(isLoading || !canSubmit)
                        .padding(.horizontal, 28)

                        Button(action: toggleMode) {
                            Text("New here? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }

                Spacer()
            }
            .padding(.top, 12)
        }
    }

    private func submit() {
        message = nil
        isLoading = true

        Task {
            do {
                if mode == .signUp {
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
                    let profile = ProfileInsert(
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
                        appState.resetOnboarding()
                        usesMockAccount = useMockAccount
                    }
                } else {
                    try await supabase.auth.signIn(email: email, password: password)
                }
            } catch {
                message = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func toggleMode() {
        message = nil
        mode = mode == .signUp ? .logIn : .signUp
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .signUp {
            return !firstName.isEmpty &&
                !lastName.isEmpty &&
                !trimmedEmail.isEmpty &&
                !password.isEmpty &&
                !confirmPassword.isEmpty
        }
        return !trimmedEmail.isEmpty && !password.isEmpty
    }
}

private struct SignUpBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.83, blue: 0.70),
                    Color(red: 0.97, green: 0.67, blue: 0.58),
                    Color(red: 0.94, green: 0.53, blue: 0.52)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.99, green: 0.84, blue: 0.72).opacity(0.9),
                    Color(red: 0.96, green: 0.70, blue: 0.58).opacity(0.85),
                    Color(red: 0.94, green: 0.52, blue: 0.52).opacity(0.9)
                ],
                center: UnitPoint(x: 0.2, y: 0.25),
                startRadius: 40,
                endRadius: 500
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.45),
                    Color.clear,
                    Color.white.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct SignUpCard: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var useMockAccount: Bool
    let isLoading: Bool
    let message: String?
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onToggleMode: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 48, height: 6)
                .padding(.top, 10)

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
                        TextField("", text: $lastName, prompt: Text("Last").foregroundColor(.gray))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
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

            Button(action: { useMockAccount.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: useMockAccount ? "checkmark.square.fill" : "square")
                        .foregroundColor(.black.opacity(0.7))
                    Text("Mock account")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.75))
                }
                Spacer()
            }
            .padding(.horizontal, 30)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: onSubmit) {
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

            Button(action: onToggleMode) {
                Text("Already have an account? ")
                    .foregroundColor(.black.opacity(0.65))
                + Text("Log In")
                    .foregroundColor(.black.opacity(0.9))
                    .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct ProfileInsert: Encodable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
}

#Preview {
    AuthView()
}
