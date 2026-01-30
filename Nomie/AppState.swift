//
//  AppState.swift
//  Nomie
//

import Foundation
import Supabase
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var session: Session?
    @Published var hasCompletedOnboarding: Bool

    private let onboardingKey = "hasCompletedOnboarding"
    private let supabase = SupabaseManager.shared
    private var authTask: Task<Void, Never>?

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.session = nil
        startAuthListener()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            // Best-effort sign out.
        }
    }

    private func startAuthListener() {
        authTask?.cancel()
        authTask = Task {
            if let currentSession = try? await supabase.auth.session {
                session = currentSession
            }

            for await (event, session) in await supabase.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn:
                    self.session = session
                case .signedOut:
                    self.session = nil
                default:
                    break
                }
            }
        }
    }
}
