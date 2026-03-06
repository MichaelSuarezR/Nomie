//
//  MeStampsView.swift
//  Nomie
//

import SwiftUI

struct MeStampsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    
    let stamps: [StampItem] = [
        StampItem(imageName: "stamp_time", isUnlocked: true),
        StampItem(imageName: "stamp_hibernator", isUnlocked: true),
        StampItem(imageName: "stamp_merrier", isUnlocked: true),
        StampItem(imageName: "stamp_bookworm", isUnlocked: true),
        StampItem(imageName: "stamp_earth", isUnlocked: true),
        StampItem(imageName: "stamp_empty", isUnlocked: false),
        StampItem(imageName: "stamp_empty", isUnlocked: false),
        StampItem(imageName: "stamp_empty", isUnlocked: false)
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            MeStampsBackground()
            
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
                    
                    Text("Stamps")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(stamps) { stamp in
                            StampCell(stamp: stamp)
                        }
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


struct StampItem: Identifiable {
    let id = UUID()
    let imageName: String
    let isUnlocked: Bool
}

struct StampCell: View {
    let stamp: StampItem
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.05))
                .aspectRatio(1, contentMode: .fit)
            
            Image(stamp.imageName)
                .resizable()
                .scaledToFit()
                .shadow(color: stamp.isUnlocked ? Color.black.opacity(0.15) : .clear, radius: 4, x: 0, y: 3)
            
            if !stamp.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.black.opacity(0.15))
            }
        }
    }
}

private struct MeStampsBackground: View {
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
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MeStampsView()
}
