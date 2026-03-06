//
//  MeView.swift
//  Nomie
//

import SwiftUI

struct MeView: View {
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    private let cardShadow = Color.black.opacity(0.06)
    
    @State private var currentStreakDays: Int = 8
    @State private var longestStreakDays: Int = 12
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                MeTabBackground()
                
                Image("planet")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .opacity(0.92)
                    .padding(.trailing, 24)
                    .padding(.top, 60)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Text("Me")
                            .font(.custom("SortsMillGoudy-Regular", size: 52))
                            .foregroundStyle(inkColor)
                            .padding(.horizontal, 24)
                            .padding(.top, 150)
                            .padding(.bottom, 24)
                        
                        HStack(spacing: 16) {
                            MeCurrentStreakCard(
                                streakDays: currentStreakDays,
                                inkColor: inkColor,
                                shadowColor: cardShadow
                            )
                            MeLongestStreakCard(
                                streakDays: longestStreakDays,
                                inkColor: inkColor,
                                shadowColor: cardShadow
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        VStack(spacing: 12) {
                            NavigationLink(destination: MeFriendsView()) {
                                MeMenuButton(title: "Friends", inkColor: inkColor, shadowColor: cardShadow)
                            }
                            
                            NavigationLink(destination: MeGoalsView()) {
                                MeMenuButton(title: "Manage Goals", inkColor: inkColor, shadowColor: cardShadow)
                            }
                            
                            NavigationLink(destination: MeStampsView()) {
                                MeMenuButton(title: "Stamps", inkColor: inkColor, shadowColor: cardShadow)
                            }
                            
                            NavigationLink(destination: MeSettingsView()) {
                                MeMenuButton(title: "Settings", inkColor: inkColor, shadowColor: cardShadow)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Color.clear.frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}


private struct MeTabBackground: View {
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
                colors: [
                    Color(red: 0.98, green: 0.83, blue: 0.67).opacity(0.42),
                    Color.clear
                ],
                center: UnitPoint(x: 0.66, y: 0.72),
                startRadius: 24,
                endRadius: 380
            )

            RadialGradient(
                colors: [
                    Color(red: 0.97, green: 0.74, blue: 0.66).opacity(0.28),
                    Color.clear
                ],
                center: UnitPoint(x: 0.94, y: 0.70),
                startRadius: 18,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.90, blue: 0.66).opacity(0.30),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: 0.04),
                startRadius: 12,
                endRadius: 220
            )
        }
        .ignoresSafeArea()
    }
}

private struct MeCurrentStreakCard: View {
    let streakDays: Int
    let inkColor: Color
    let shadowColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image("Streak")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                
                Text("Streaks")
                    .font(.custom("AvenirNext-Medium", size: 16))
                    .foregroundStyle(inkColor)
            }
            .padding(.top, 24)
            
            Spacer(minLength: 0)
            
            Text("\(streakDays)")
                .font(.custom("AvenirNext-Bold", size: 76))
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.98, green: 0.53, blue: 0.42), location: 0.02),
                            .init(color: Color(red: 0.97, green: 0.66, blue: 0.38), location: 0.48),
                            .init(color: Color(red: 0.90, green: 0.72, blue: 0.36), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(streakDays == 1 ? "Day" : "Days")
                .font(.custom("AvenirNext-Medium", size: 16))
                .foregroundStyle(inkColor)
                .padding(.top, -15)
            
            Spacer(minLength: 0)
            
            Text("Keep that momentum\ngoing!")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(inkColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        )
    }
}

private struct MeLongestStreakCard: View {
    let streakDays: Int
    let inkColor: Color
    let shadowColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("active")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Longest Streak:")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(inkColor)
                
                Text("\(streakDays) " + (streakDays == 1 ? "Day" : "Days"))
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(inkColor)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.96, blue: 0.84),
                            Color(red: 0.98, green: 0.82, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        )
    }
}

private struct MeMenuButton: View {
    let title: String
    let inkColor: Color
    let shadowColor: Color
    
    var body: some View {
        Text(title)
            .font(.custom("AvenirNext-Regular", size: 16))
            .foregroundStyle(inkColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            )
    }
}

#Preview {
    MeView()
}
