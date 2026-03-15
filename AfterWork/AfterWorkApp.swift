//
//  AfterWorkApp.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct AfterWorkApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
