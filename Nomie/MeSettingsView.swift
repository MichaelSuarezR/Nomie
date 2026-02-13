//
//  MeSettingsView.swift
//  Nomie
//

import SwiftUI

struct MeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let buttonColor = Color.black.opacity(0.1)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(inkColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        
                        SettingsButton(title: "EDIT PROFILE", action: {})
                        SettingsButton(title: "CHANGE PASSWORD", action: {})
                        SettingsButton(title: "NOTIFICATIONS", action: {})
                        
                        NavigationLink(destination: MeAppTrackingView()) {
                            SettingsPillLabel(title: "APP TRACKING")
                        }
                        
                        NavigationLink(destination: MeAppCategoriesView()) {
                            SettingsPillLabel(title: "APP CATEGORIES")
                        }
                        
                        SettingsButton(title: "WIDGET SETUP", action: {})
                        SettingsButton(title: "TERMS OF SERVICE", action: {})
                        SettingsButton(title: "PRIVACY POLICY", action: {})
                        
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(surfaceColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}


struct SettingsPillLabel: View {
    let title: String
    private let buttonColor = Color.black.opacity(0.1)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    var body: some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 16))
            .foregroundStyle(inkColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(buttonColor)
            )
    }
}

struct SettingsButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsPillLabel(title: title)
        }
    }
}

#Preview {
    MeSettingsView()
}
