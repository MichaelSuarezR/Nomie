//
//  AuthView.swift
//  Nomie
//

import SwiftUI
import Supabase

struct AuthView: View {
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
    @State private var isLoading = false
    @State private var message: String?

    private let supabase = SupabaseManager.shared

    init(initialMode: Mode = .signUp) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(mode == .signUp ? "Create your account" : "Welcome back")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 14) {
                if mode == .signUp {
                    TextField("First Name", text: $firstName, prompt: Text("First Name").foregroundColor(.gray))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    TextField("Last Name", text: $lastName, prompt: Text("Last Name").foregroundColor(.gray))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

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

                if mode == .signUp {
                    SecureField("Confirm Password", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.gray))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
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
                Text(isLoading ? "Please wait..." : (mode == .signUp ? "Sign Up" : "Log In"))
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
                Text(mode == .signUp ? "Already have an account? Log In" : "New here? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()
        }
        .padding(.top, 12)
        .background(Color.white.ignoresSafeArea())
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

private struct ProfileInsert: Encodable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
}

#Preview {
    AuthView()
}
