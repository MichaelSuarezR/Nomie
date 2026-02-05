//
//  MeGoalsView.swift
//  Nomie
//

import SwiftUI

struct MeGoalsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let cardColor = Color(red: 0.85, green: 0.85, blue: 0.85)
    private let buttonColor = Color.black.opacity(0.1)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                HStack(spacing: 16) {
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
                    Text("My Goals")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("Weekly Screentime")
                                .font(.custom("AvenirNext-Medium", size: 18))
                                .foregroundStyle(inkColor.opacity(0.8))
                            
                            Text("4H 32M")
                                .font(.custom("AvenirNext-Bold", size: 56))
                                .foregroundStyle(inkColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(cardColor)
                        )
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 16)
                                    
                                    Capsule()
                                        .fill(inkColor)
                                        .frame(width: geometry.size.width * 0.5, height: 16)
                                }
                            }
                            .frame(height: 16)
                            
                            HStack {
                                Text("GOAL PROGRESS")
                                    .font(.custom("AvenirNext-BoldItalic", size: 14))
                                    .foregroundStyle(inkColor)
                                Spacer()
                                Text("50%")
                                    .font(.custom("AvenirNext-BoldItalic", size: 14))
                                    .foregroundStyle(inkColor)
                            }
                            
                            Text("You are ON TRACK to meet your goal!")
                                .font(.custom("AvenirNext-MediumItalic", size: 14))
                                .foregroundStyle(inkColor.opacity(0.8))
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                        
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                        }) {
                            Text("EDIT ZINE PREFERENCES")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                                .foregroundStyle(inkColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(buttonColor))
                        }
                        
                        Button(action: {
                        }) {
                            Text("EDIT MY GOALS")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                                .foregroundStyle(inkColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(buttonColor))
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 12)
                    
                    HStack {
                        Spacer()
                        Image("Illustration300 1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 10)
                            .opacity(0.9)
                        Spacer()
                    }
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(surfaceColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MeGoalsView()
}
