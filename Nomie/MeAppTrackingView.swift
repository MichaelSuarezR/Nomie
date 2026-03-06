//
//  MeAppTrackingView.swift
//  Nomie
//

import SwiftUI

struct AppTrackingItem: Identifiable {
    let id = UUID()
    let name: String
    let assetName: String
    var isEnabled: Bool
}

//add or remove apps to track functionality??

struct MeAppTrackingView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    
    @State private var apps: [AppTrackingItem] = [
        AppTrackingItem(name: "Instagram", assetName: "instagram", isEnabled: true),
        AppTrackingItem(name: "Spotify", assetName: "spotify", isEnabled: true),
        AppTrackingItem(name: "Kindle", assetName: "kindle", isEnabled: true),
        AppTrackingItem(name: "Notion", assetName: "notion", isEnabled: false),
        AppTrackingItem(name: "Procreate", assetName: "procreate", isEnabled: true),
        AppTrackingItem(name: "Flora", assetName: "flora", isEnabled: false),
        AppTrackingItem(name: "White Noise", assetName: "whitenoise", isEnabled: false)
    ]
    
    var body: some View {
        ZStack {
            AppTrackingBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(inkColor)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    Spacer()
                    Text("App Tracking")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Select which apps to track")
                            .font(.custom("SortsMillGoudy-Regular", size: 24))
                            .foregroundStyle(inkColor)
                        
                        Text("When you uncheck an app it will no longer track your activity.")
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundStyle(inkColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach($apps) { $app in
                                AppTrackingRow(app: $app, inkColor: inkColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct AppTrackingRow: View {
    @Binding var app: AppTrackingItem
    let inkColor: Color
    
    private let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        HStack(spacing: 14) {
            Image(app.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(app.name)
                .font(.custom("AvenirNext-Medium", size: 16))
                .foregroundStyle(inkColor)
            
            Spacer()
            
            Button {
                impactMed.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    app.isEnabled.toggle()
                }
            } label: {
                ZStack(alignment: app.isEnabled ? .trailing : .leading) {
                    Capsule()
                        .fill(app.isEnabled ? AnyShapeStyle(activeGradient) : AnyShapeStyle(inactiveGradient))
                        .frame(width: 50, height: 28)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, 2)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    private var activeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.98, green: 0.78, blue: 0.58), Color(red: 0.92, green: 0.70, blue: 0.62)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var inactiveGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.91, green: 0.94, blue: 0.82), Color(red: 0.98, green: 0.98, blue: 0.95)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct AppTrackingBackground: View {
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
