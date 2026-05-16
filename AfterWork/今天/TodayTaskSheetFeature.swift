//
//  TodayTaskSheetFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

@Reducer
public struct TodayTaskSheetFeature {
    @ObservableState
    public struct State: Equatable {
        public var taskTitle: String = ""
        public init(taskTitle: String = "") {
            self.taskTitle = taskTitle
        }
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case confirmButtonTapped
        case cancelButtonTapped
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case saveTask(title: String)
        }
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .confirmButtonTapped:
                return .send(.delegate(.saveTask(title: state.taskTitle)))
            case .cancelButtonTapped:
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
