//
//  MeSettingsView.swift
//  Nomie
//

import SwiftUI

struct MeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    private let cardShadow = Color.black.opacity(0.06)
    
    var body: some View {
        ZStack {
            MeSettingsBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(inkColor)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    Spacer()
                    Text("Settings")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        
                        SettingsMenuButton(icon: "pencil", title: "Edit Profile", inkColor: inkColor, shadowColor: cardShadow)
                        
                        SettingsMenuButton(icon: "lock", title: "Change Password", inkColor: inkColor, shadowColor: cardShadow)
                        
                        SettingsMenuButton(icon: "bell", title: "Notifications", inkColor: inkColor, shadowColor: cardShadow)
                        
                        NavigationLink(destination: MeAppTrackingView()) {
                            SettingsMenuButton(icon: "chart.bar", title: "App Tracking", inkColor: inkColor, shadowColor: cardShadow)
                        }
                        
                        NavigationLink(destination: MeAppCategoriesView()) {
                            SettingsMenuButton(icon: "folder", title: "App Categories", inkColor: inkColor, shadowColor: cardShadow)
                        }
                        
                        SettingsMenuButton(icon: "doc.text", title: "Terms of Service", inkColor: inkColor, shadowColor: cardShadow)
                        
                        SettingsMenuButton(icon: "shield", title: "Privacy Policy", inkColor: inkColor, shadowColor: cardShadow)
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    Color.clear.frame(height: 120)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SettingsMenuButton: View {
    let icon: String
    let title: String
    let inkColor: Color
    let shadowColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(inkColor.opacity(0.8))
            
            Text(title)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundStyle(inkColor)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

private struct MeSettingsBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.98, green: 0.94, blue: 0.80), location: 0.0),
                    .init(color: Color(red: 0.95, green: 0.97, blue: 0.90), location: 0.56),
                    .init(color: Color(red: 0.99, green: 0.93, blue: 0.88), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .topTrailing
            )
            RadialGradient(
                colors: [Color(red: 0.98, green: 0.83, blue: 0.67).opacity(0.42), Color.clear],
                center: UnitPoint(x: 0.66, y: 0.72),
                startRadius: 24,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}
