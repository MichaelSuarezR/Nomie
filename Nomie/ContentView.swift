//
//  ContentView.swift
//  Nomie
//
//  Created by Michael Suarez-Russell on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            EmptyTabView(title: "Focus")
                .tabItem {
                    Label("Focus", systemImage: "bolt.circle")
                }

            EmptyTabView(title: "Ticket")
                .tabItem {
                    Label("Ticket", systemImage: "ticket")
                }

            EmptyTabView(title: "Reflect")
                .tabItem {
                    Label("Reflect", systemImage: "sparkles")
                }

            EmptyTabView(title: "Me")
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}

struct EmptyTabView: View {
    let title: String

    var body: some View {
        NavigationStack {
            Text("")
                .navigationTitle(title)
        }
    }
}
