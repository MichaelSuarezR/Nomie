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
    @State private var email = ""
    @State private var password = ""
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
                Text(isLoading ? "Please wait..." : (mode == .signUp ? "Sign Up" : "Log In"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
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
                    try await supabase.auth.signUp(email: email, password: password)
                    message = "Check your inbox to verify your email, then log in."
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
}

#Preview {
    AuthView()
}
