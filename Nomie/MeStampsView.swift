//
//  MeStampsView.swift
//  Nomie
//

import SwiftUI

struct MeStampsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let emptySlotColor = Color(red: 0.85, green: 0.85, blue: 0.85)
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
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
                    
                    Text("Stamp Collection")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<12, id: \.self) { index in
                            StampSlot(color: emptySlotColor)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 20)
                    
                    Button(action: {
                    }) {
                        Text("VIEW ALL\nSTAMPS")
                            .font(.custom("AvenirNext-DemiBold", size: 20))
                            .foregroundStyle(inkColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 60)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(surfaceColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

struct StampSlot: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(color)
            .aspectRatio(1.0, contentMode: .fit)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MeStampsView()
}
