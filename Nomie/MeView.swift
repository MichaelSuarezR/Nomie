//
//  MeView.swift
//  Nomie
//

import SwiftUI
import Supabase

struct MeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let email = appState.session?.user.email {
                    Text(email)
                        .font(.headline)
                }

                Button("Sign Out") {
                    Task {
                        await appState.signOut()
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Me")
        }
    }
}

#Preview {
    MeView()
        .environmentObject(AppState())
}
