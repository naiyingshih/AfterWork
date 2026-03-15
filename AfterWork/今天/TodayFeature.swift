//
//  TodayFeature.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct TodayFeature {
    @ObservableState
    struct State: Equatable {
        var searchText: String = ""
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
