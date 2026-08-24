//
//  GoalFormFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation

@Reducer
struct GoalFormFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var description: String = ""
        var targetDate: Date
        var mode: Mode
        
        enum Mode: Equatable {
            case add
            case edit(Goal)
        }
        
        init(mode: Mode = .add) {
            @Dependency(\.date.now) var now
            self.mode = mode
            self.targetDate = now
            if case let .edit(goal) = mode {
                self.title = goal.title
                self.description = goal.description ?? ""
                if let date = goal.targetDate {
                    self.targetDate = date
                }
            }
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case delegate(Delegate)
        
        enum Delegate {
            case saveGoal(Goal)
        }
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .saveButtonTapped:
                let goal: Goal
                switch state.mode {
                case .add:
                    goal = Goal(
                        id: uuid().uuidString,
                        title: state.title,
                        description: state.description,
                        targetDate: state.targetDate,
                        details: [],
                        createdTime: date(),
                        updatedTime: date()
                    )
                case .edit(var existingGoal):
                    existingGoal.title = state.title
                    existingGoal.description = state.description
                    existingGoal.targetDate = state.targetDate
                    existingGoal.updatedTime = date()
                    goal = existingGoal
                }
                return .send(.delegate(.saveGoal(goal)))
                
            case .cancelButtonTapped:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
