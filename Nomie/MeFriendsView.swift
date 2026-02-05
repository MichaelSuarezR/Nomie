//
//  MeFriendsView.swift
//  Nomie
//

import SwiftUI

struct MeFriendsView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let buttonColor = Color.black.opacity(0.1)
    
    let friends: [FriendItem] = [
        FriendItem(rank: "01", name: "User_A", streak: 100),
        FriendItem(rank: "02", name: "User_B", streak: 98),
        FriendItem(rank: "03", name: "User_C", streak: 92),
        FriendItem(rank: "04", name: "User_D", streak: 85),
        FriendItem(rank: "05", name: "User_E", streak: 60),
        FriendItem(rank: "06", name: "User_F", streak: 45),
        FriendItem(rank: "07", name: "User_G", streak: 21),
        FriendItem(rank: "08", name: "User_H", streak: 12)
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
                    
                    Text("Friends")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Community Streaks")
                            .font(.custom("AvenirNext-Bold", size: 18))
                            .foregroundStyle(inkColor)
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("ADD CONNECTION")
                            }
                            .font(.custom("AvenirNext-DemiBold", size: 18))
                            .foregroundStyle(inkColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(buttonColor)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 8)
                        
                        VStack(spacing: 0) {
                            ForEach(friends) { friend in
                                FriendRow(friend: friend, inkColor: inkColor)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(surfaceColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

struct FriendItem: Identifiable {
    let id = UUID()
    let rank: String
    let name: String
    let streak: Int
}

struct FriendRow: View {
    let friend: FriendItem
    let inkColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("\(friend.rank) / \(friend.name)")
                    .font(.custom("AvenirNext-Bold", size: 18))
                    .foregroundStyle(inkColor)
                
                Circle()
                    .fill(inkColor)
                    .frame(width: 14, height: 14)
                
                Spacer()
                
                Text("\(friend.streak) Days")
                    .font(.custom("AvenirNext-Bold", size: 18))
                    .foregroundStyle(inkColor)
            }
            .padding(.vertical, 16)
            
            Rectangle()
                .fill(inkColor)
                .frame(height: 1.5)
        }
    }
}

#Preview {
    MeFriendsView()
}
