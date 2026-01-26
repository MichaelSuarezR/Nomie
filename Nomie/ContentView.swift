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
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "bolt.circle")
                }

            TicketView()
                .tabItem {
                    Label("Ticket", systemImage: "ticket")
                }

            ReflectView()
                .tabItem {
                    Label("Reflect", systemImage: "sparkles")
                }

            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}
