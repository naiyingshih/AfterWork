//
//  CalendarFeature.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var username: String = "Guest"
        var isLoggedIn: Bool = false
    }
    
    enum Action {
        case loginButtonTapped
        case logoutButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loginButtonTapped:
                state.isLoggedIn = true
                state.username = "User"
                return .none
                
            case .logoutButtonTapped:
                state.isLoggedIn = false
                state.username = "Guest"
                return .none
            }
        }
    }
}
