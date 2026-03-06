//
//  MeGoalsView.swift
//  Nomie
//

import SwiftUI

struct MeGoalsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    
    var body: some View {
        ZStack {
            MeGoalsBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(inkColor)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    Text("Manage Goals")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 32) {
                            
                            VStack(spacing: 4) {
                                Text("Weekly Screentime")
                                    .font(.custom("SortsMillGoudy-Regular", size: 24))
                                    .foregroundStyle(inkColor)
                                
                                Text("4H 32M")
                                    .font(.custom("SortsMillGoudy-Regular", size: 60))
                                    .foregroundStyle(inkColor)
                            }
                            .padding(.top, 16)
                            
                            VStack(spacing: 12) {
                                GoalsProgressBar(progress: 0.50)
                                
                                HStack {
                                    Text("Goal Progress")
                                        .font(.custom("AvenirNext-DemiBold", size: 14))
                                        .foregroundStyle(inkColor)
                                    Spacer()
                                    Text("50%")
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundStyle(inkColor)
                                }
                            }
                            
                            Text("You are on track to meet your goal!")
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundStyle(inkColor.opacity(0.7))
                                .padding(.bottom, 16)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.96))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                        }) {
                            Text("Set Goals")
                                .font(.custom("AvenirNext-Regular", size: 16))
                                .foregroundStyle(inkColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.96))
                                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(.horizontal, 24)
                        
                    }
                    
                    Color.clear.frame(height: 120)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct GoalsProgressBar: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let fillWidth = max(24, proxy.size.width * progress)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.91, green: 0.94, blue: 0.82))
                    .frame(height: 16)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.82, blue: 0.66),
                                Color(red: 0.94, green: 0.76, blue: 0.74)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 16)
                    .mask(
                        Capsule()
                            .frame(width: fillWidth, height: 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                
                Capsule()
                    .stroke(Color(red: 0.64, green: 0.49, blue: 0.45), lineWidth: 1)
                    .frame(width: fillWidth, height: 16)
            }
        }
        .frame(height: 16)
    }
}

private struct MeGoalsBackground: View {
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

#Preview {
    MeGoalsView()
}
