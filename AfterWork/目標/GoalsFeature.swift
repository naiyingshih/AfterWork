//
//  GoalsFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct GoalsFeature {
    
    @ObservableState
    struct State: Equatable {
        var goals: IdentifiedArrayOf<Goal> = []
        var goalForm: GoalFormFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        var isLoading: Bool = false
    }
    
    enum Action {
        case onAppear
        case goalsLoaded([Goal])
        case addGoalButtonTapped
        case goalForm(GoalFormFeature.Action)
        case goal(IdentifiedActionOf<GoalFeature>)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case confirmDelete(Goal.ID)
        }
    }
    
    @Dependency(\.goalsRepository) var goalsRepository
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let goals = try await goalsRepository.fetchGoals()
                        await send(.goalsLoaded(goals))
                    } catch {
                        print("Failed to load goals: \(error)")
                        await send(.goalsLoaded([]))
                    }
                }
                
            case let .goalsLoaded(loadedGoals):
                state.goals = IdentifiedArrayOf(uniqueElements: loadedGoals.sorted(by: { $0.createdTime > $1.createdTime }))
                state.isLoading = false
                return .none
                
            case .addGoalButtonTapped:
                state.goalForm = GoalFormFeature.State(mode: .add)
                return .none
                
            case let .goalForm(.delegate(.saveGoal(goal))):
                state.goals.updateOrAppend(goal)
                state.goalForm = nil
                return .run { _ in
                    do {
                        try await goalsRepository.saveGoal(goal)
                    } catch {
                        print("Save goal failed: \(error)")
                    }
                }
                
            case .goalForm(.cancelButtonTapped):
                state.goalForm = nil
                return .none
                
            case .goalForm:
                return .none
                
            case let .goal(.element(id: id, action: .delegate(.saveGoal(goal)))):
                state.goals[id: id] = goal
                return .run { _ in
                    do {
                        try await goalsRepository.saveGoal(goal)
                    } catch {
                        print("Save goal details failed: \(error)")
                    }
                }
                
            case let .goal(.element(id: id, action: .delegate(.updateGoalDetails(goalId, details)))):
                state.goals[id: id]?.details = details
                state.goals[id: id]?.updatedTime = Date()
                return .run { _ in
                    do {
                        try await goalsRepository.updateGoalDetails(goalId, Array(details))
                    } catch {
                        print("Update goal items failed: \(error)")
                    }
                }
                
            case let .goal(.element(id: id, action: .delegate(.editGoal(goal)))):
                state.goalForm = GoalFormFeature.State(mode: .edit(goal))
                return .none
                
            case let .goal(.element(id: id, action: .delegate(.deleteGoal(goalId)))):
                state.alert = AlertState {
                    TextState("確定刪除此目標？")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(goalId)) {
                        TextState("是")
                    }
                    ButtonState(role: .cancel) {
                        TextState("否")
                    }
                }
                return .none
                
            case .goal:
                return .none
                
            case .alert(.dismiss):
                return .none
                
            case let .alert(.presented(.confirmDelete(id))):
                state.goals.remove(id: id)
                return .run { _ in
                    do {
                        try await goalsRepository.deleteGoal(id)
                    } catch {
                        print("Delete goal failed: \(error)")
                    }
                }
            }
        }
        .ifLet(\.goalForm, action: \.goalForm) {
            GoalFormFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(
            \.goals,
            action: \.goal
        ) {
            GoalFeature()
        }
    }
}
