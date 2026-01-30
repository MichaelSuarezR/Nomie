//
//  NomieApp.swift
//  Nomie
//
//  Created by Michael Suarez-Russell on 1/16/26.
//

import SwiftUI

@main
struct NomieApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
