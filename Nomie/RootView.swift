//
//  RootView.swift
//  Nomie
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.session == nil {
                OnboardingFlowView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingFlowView()
            } else {
                ContentView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
