//
//  HabitManageFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

@Reducer
public struct HabitManageFeature {
    @ObservableState
    public struct State: Equatable {
        public var habit: Habit
        public var isEditing: Bool
        
        public init(habit: Habit = Habit(title: "", type: .health, repeatRule: .daily), isEditing: Bool = false) {
            self.habit = habit
            self.isEditing = isEditing
        }
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case saveHabit(Habit)
        }
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                return .send(.delegate(.saveHabit(state.habit)))
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
