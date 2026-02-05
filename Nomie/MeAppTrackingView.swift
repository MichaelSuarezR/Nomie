//
//  MeAppTrackingView.swift
//  Nomie
//

import SwiftUI

struct MeAppTrackingView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    @State private var apps: [TrackedAppItem] = [
        TrackedAppItem(name: "Instagram", isTracking: true),
        TrackedAppItem(name: "TikTok", isTracking: true),
        TrackedAppItem(name: "Twitter", isTracking: true),
        TrackedAppItem(name: "Snapchat", isTracking: true),
        TrackedAppItem(name: "YouTube", isTracking: true),
        TrackedAppItem(name: "Netflix", isTracking: false)
    ]
    
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
                    
                    Text("App Tracking")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    Text("When you uncheck an app, we’ll no longer track your activity on it")
                        .font(.custom("AvenirNext-Italic", size: 16))
                        .foregroundStyle(inkColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                    
                    HStack {
                        Text("Apps")
                            .font(.custom("AvenirNext-Medium", size: 18))
                            .foregroundStyle(inkColor)
                        Spacer()
                        Text("Categories")
                            .font(.custom("AvenirNext-Medium", size: 18))
                            .foregroundStyle(inkColor)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    VStack(spacing: 20) {
                        ForEach($apps) { $app in
                            AppTrackingRow(app: $app)
                        }
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(surfaceColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}


struct TrackedAppItem: Identifiable {
    let id = UUID()
    let name: String
    var isTracking: Bool
}

struct AppTrackingRow: View {
    @Binding var app: TrackedAppItem
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(inkColor)
                .frame(width: 48, height: 48)
            
            Text(app.name)
                .font(.custom("AvenirNext-Bold", size: 18))
                .foregroundStyle(inkColor)
            
            Spacer()
            
            Toggle("", isOn: $app.isTracking)
                .labelsHidden()
                .tint(Color(red: 0.4, green: 0.8, blue: 0.4))
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    MeAppTrackingView()
}
