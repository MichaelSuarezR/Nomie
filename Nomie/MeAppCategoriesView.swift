//
//  MeAppCategoriesView.swift
//  Nomie
//

import SwiftUI

struct MeAppCategoriesView: View {
    @Environment(\.dismiss) var dismiss
    
    private let surfaceColor = Color(red: 0.985, green: 0.975, blue: 0.955)
    private let inkColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    
    let availableCategories = [
        "Creativity",
        "Connection",
        "Drifting",
        "Entertainment",
        "Productivity",
        "Learning"
    ]
    
    @State private var apps: [CategoryAppItem] = [
        CategoryAppItem(name: "Instagram", category: nil),
        CategoryAppItem(name: "TikTok", category: nil),
        CategoryAppItem(name: "Twitter", category: nil),
        CategoryAppItem(name: "Snapchat", category: nil),
        CategoryAppItem(name: "YouTube", category: nil),
        CategoryAppItem(name: "Duolingo", category: nil)
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
                    
                    Text("App Categories")
                        .font(.custom("Georgia", size: 34))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 24)
                    
                    Text("Select which category you’d like your apps to fall under")
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
                            CategoryRow(
                                app: $app,
                                categories: availableCategories,
                                inkColor: inkColor
                            )
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

struct CategoryAppItem: Identifiable {
    let id = UUID()
    let name: String
    var category: String?
}

struct CategoryRow: View {
    @Binding var app: CategoryAppItem
    let categories: [String]
    let inkColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(inkColor)
                .frame(width: 48, height: 48)
            
            Text(app.name)
                .font(.custom("AvenirNext-Bold", size: 18))
                .foregroundStyle(inkColor)
            
            Spacer()
            
            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        app.category = category
                    }
                }
            } label: {
                HStack {
                    Text(app.category ?? "Select")
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundStyle(inkColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(inkColor)
                }
                .padding(.horizontal, 12)
                .frame(width: 120, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(inkColor, lineWidth: 1)
                        .background(Color.white.cornerRadius(8))
                )
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    MeAppCategoriesView()
}
