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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
