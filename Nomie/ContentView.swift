//
//  ContentView.swift
//  Nomie
//
//  Created by Michael Suarez-Russell on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .focus
    @State private var previousTab: AppTab = .focus
    private let tabBarHeight: CGFloat = 70
    private let tabBarBottomPadding: CGFloat = 10
    private let tabBarExtraClearance: CGFloat = 24
    private let tabOrder: [AppTab] = [.focus, .ticket, .reflect, .me]

    var body: some View {
        ZStack {
            FocusView()
                .offset(x: offset(for: .focus, in: geometryWidth))
            TicketView()
                .offset(x: offset(for: .ticket, in: geometryWidth))
            ReflectView()
                .offset(x: offset(for: .reflect, in: geometryWidth))
            MeView()
                .offset(x: offset(for: .me, in: geometryWidth))
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: tabBarHeight + tabBarBottomPadding + tabBarExtraClearance)
        }
        .overlay(alignment: .bottom) {
            NomieTabBar(selectedTab: $selectedTab, previousTab: $previousTab)
                .padding(.horizontal, 16)
                .padding(.bottom, tabBarBottomPadding)
        }
    }

    private var geometryWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    private func offset(for tab: AppTab, in width: CGFloat) -> CGFloat {
        let selectedIndex = tabOrder.firstIndex(of: selectedTab) ?? 0
        let tabIndex = tabOrder.firstIndex(of: tab) ?? 0
        return CGFloat(tabIndex - selectedIndex) * width
    }
}

private enum AppTab: CaseIterable {
    case focus
    case ticket
    case reflect
    case me

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .ticket: return "Ticket"
        case .reflect: return "Reflect"
        case .me: return "Me"
        }
    }

    var systemImage: String {
        switch self {
        case .focus: return "square.grid.2x2.fill"
        case .ticket: return "ticket.fill"
        case .reflect: return "pencil"
        case .me: return "person.fill"
        }
    }
}

private struct NomieTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var previousTab: AppTab

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: tab == selectedTab
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        previousTab = selectedTab
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.86, blue: 0.76),
                            Color(red: 0.99, green: 0.65, blue: 0.56)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

private struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isSelected {
                HStack(spacing: 10) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                    Text(tab.title)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.95, green: 0.30, blue: 0.42))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.30, blue: 0.42))
                }
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
