//
//  MeView.swift
//  Nomie
//

import SwiftUI

struct MeView: View {
    @EnvironmentObject var appState: AppState
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let buttonColor = Color.black.opacity(0.08)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .opacity(0)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("My Dashboard")
                            .font(.custom("Georgia", size: 34))
                            .foregroundStyle(inkColor)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Text("Streak Status")
                                    .font(.custom("AvenirNext-Bold", size: 16))
                                    .foregroundStyle(inkColor)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            HStack(spacing: 24) {
                                Text("14 Days")
                                    .font(.custom("AvenirNext-DemiBold", size: 22))
                                    .foregroundStyle(inkColor)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.black.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Longest:")
                                        .font(.custom("AvenirNext-Medium", size: 16))
                                        .foregroundStyle(inkColor.opacity(0.7))
                                    Text("28 Days")
                                        .font(.custom("AvenirNext-Bold", size: 16))
                                        .foregroundStyle(inkColor)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            Image("Illustration302 1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            Text("Consistency is key! Keep that\nmomentum going!")
                                .font(.custom("AvenirNext-Medium", size: 16))
                                .foregroundStyle(inkColor.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        VStack(spacing: 16) {
                            NavigationLink(destination: MeFriendsView()) {
                                MeMenuButton(title: "FRIENDS", color: buttonColor, textColor: inkColor)
                            }
                            
                            NavigationLink(destination: MeSettingsView()) {
                                MeMenuButton(title: "SETTINGS", color: buttonColor, textColor: inkColor)
                            }
                            
                            NavigationLink(destination: MeStampsView()) {
                                MeMenuButton(title: "STAMPS", color: buttonColor, textColor: inkColor)
                            }
                            
                            NavigationLink(destination: MeGoalsView()) {
                                MeMenuButton(title: "MANAGE GOALS", color: buttonColor, textColor: inkColor)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        
                        Button(action: {
                            Task { await appState.signOut() }
                        }) {
                            Text("Sign Out")
                                .font(.custom("AvenirNext-Medium", size: 14))
                                .foregroundStyle(.red.opacity(0.7))
                                .underline()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .background(surfaceColor.ignoresSafeArea())
        }
    }
}


struct MeMenuButton: View {
    let title: String
    let color: Color
    let textColor: Color
    
    var body: some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 18))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

#Preview {
    MeView()
        .environmentObject(AppState())
}
