//
//  MeFriendsView.swift
//  Nomie
//

import SwiftUI

struct MeFriendsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    
    let friends: [HiFiFriendItem] = [
        HiFiFriendItem(rank: "01", name: "alex_chen92", streak: 143),
        HiFiFriendItem(rank: "02", name: "maria_g", streak: 128),
        HiFiFriendItem(rank: "03", name: "jasonlee", streak: 117),
        HiFiFriendItem(rank: "04", name: "sophia.k", streak: 105),
        HiFiFriendItem(rank: "05", name: "david_w", streak: 96),
        HiFiFriendItem(rank: "06", name: "emily_park", streak: 88),
        HiFiFriendItem(rank: "07", name: "kevinliu", streak: 79),
        HiFiFriendItem(rank: "08", name: "rachelm", streak: 72),
        HiFiFriendItem(rank: "09", name: "chris_03", streak: 64),
        HiFiFriendItem(rank: "10", name: "linda.zhang", streak: 58),
        HiFiFriendItem(rank: "11", name: "mike_b", streak: 49),
        HiFiFriendItem(rank: "12", name: "sarah_j", streak: 41),
        HiFiFriendItem(rank: "13", name: "tommy.t", streak: 33)
    ]
    
    var body: some View {
        ZStack {
            MeFriendsBackground()
            
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
                    
                    Text("Friends")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                VStack(spacing: 20) {
                    
                    Text("View your community's streaks!")
                        .font(.custom("SortsMillGoudy-Regular", size: 24))
                        .foregroundStyle(inkColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("Add Connection")
                                .font(.custom("AvenirNext-Medium", size: 16))
                        }
                        .foregroundStyle(inkColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.94, green: 0.93, blue: 0.76),
                                            Color(red: 0.88, green: 0.91, blue: 0.70)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 4)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(friends) { friend in
                                HiFiFriendRow(friend: friend, inkColor: inkColor)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct HiFiFriendItem: Identifiable {
    let id = UUID()
    let rank: String
    let name: String
    let streak: Int
}

struct HiFiFriendRow: View {
    let friend: HiFiFriendItem
    let inkColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(friend.rank)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(Color.black.opacity(0.6))
                .frame(width: 34, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
            
            Text(friend.name)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundStyle(inkColor)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image("Streak")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                
                Text("\(friend.streak) Days")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(inkColor)
                    .frame(width: 75, alignment: .leading)
            }
        }
    }
}

private struct MeFriendsBackground: View {
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
    MeFriendsView()
}
