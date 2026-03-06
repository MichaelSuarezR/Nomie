//
//  MeAppCategoriesView.swift
//  Nomie
//

import SwiftUI

struct AppCategoryAssignment: Identifiable {
    let id = UUID()
    let name: String
    let assetName: String
    var selectedCategory: String?
}

struct MeAppCategoriesView: View {
    @Environment(\.dismiss) var dismiss
    
    private let inkColor = Color(red: 0.2, green: 0.25, blue: 0.2)
    private let categories = ["Social", "Productivity", "Entertainment", "Reading", "Health", "Creativity"]
    
    @State private var assignments: [AppCategoryAssignment] = [
        AppCategoryAssignment(name: "Instagram", assetName: "instagram"),
        AppCategoryAssignment(name: "Spotify", assetName: "spotify"),
        AppCategoryAssignment(name: "Kindle", assetName: "kindle"),
        AppCategoryAssignment(name: "Notion", assetName: "notion"),
        AppCategoryAssignment(name: "Procreate", assetName: "procreate"),
        AppCategoryAssignment(name: "Flora", assetName: "flora"),
        AppCategoryAssignment(name: "White Noise", assetName: "whitenoise")
    ]
    
    var body: some View {
        ZStack {
            MeAppCategoriesBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(inkColor)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    Spacer()
                    Text("App Categories")
                        .font(.custom("SortsMillGoudy-Regular", size: 30))
                        .foregroundStyle(inkColor)
                        .padding(.trailing, 44)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                VStack(spacing: 0) {
                    Text("Select which category\nyou'd like your apps to fall under")
                        .font(.custom("AvenirNext-Regular", size: 15))
                        .foregroundStyle(inkColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                    
                    HStack {
                        Text("Apps")
                            .font(.custom("AvenirNext-Bold", size: 16))
                        Spacer()
                        Text("Categories")
                            .font(.custom("AvenirNext-Bold", size: 16))
                    }
                    .foregroundStyle(inkColor)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach($assignments) { $item in
                                CategoryAssignmentRow(item: $item, categories: categories, inkColor: inkColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CategoryAssignmentRow: View {
    @Binding var item: AppCategoryAssignment
    let categories: [String]
    let inkColor: Color
    
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let dropdownWidth: CGFloat = 140
    
    var body: some View {
        HStack(spacing: 12) {
            Image(item.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(item.name)
                .font(.custom("AvenirNext-Medium", size: 15))
                .foregroundStyle(inkColor)
            
            Spacer()
            
            Menu {
                ForEach(categories, id: \.self) { cat in
                    Button(cat) {
                        impact.impactOccurred()
                        item.selectedCategory = cat
                    }
                }
            } label: {
                HStack {
                    Text(item.selectedCategory ?? "Select")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(item.selectedCategory == nil ? inkColor.opacity(0.4) : inkColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(inkColor.opacity(0.3))
                }
                .padding(.horizontal, 12)
                .frame(width: dropdownWidth, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }
}

private struct MeAppCategoriesBackground: View {
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

#Preview {
    MeAppCategoriesView()
}
