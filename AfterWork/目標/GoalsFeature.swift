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
        /// 由 AppFeature 的 Firestore listener 餵進來（forEach 需要可寫入的儲存屬性，接不上 @Shared）。
        var goals: IdentifiedArrayOf<Goal> = []
        @Presents var goalForm: GoalFormFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        
        var uncompletedGoals: IdentifiedArrayOf<Goal> {
            let filtered = goals.filter { !$0.isCompleted }
            return IdentifiedArray(uniqueElements: filtered.sorted(by: Self.sortGoals))
        }
        
        var completedGoals: IdentifiedArrayOf<Goal> {
            let filtered = goals.filter { $0.isCompleted }
            return IdentifiedArray(uniqueElements: filtered.sorted(by: Self.sortCompletedGoals))
        }
        
        /// 未完成：預計完成日近的排前面，沒有預計完成日的排最後。
        static func sortGoals(_ goal1: Goal, _ goal2: Goal) -> Bool {
            if let d1 = goal1.targetDate, let d2 = goal2.targetDate {
                if d1 == d2 {
                    return goal1.createdTime > goal2.createdTime
                }
                return d1 < d2
            } else if goal1.targetDate != nil {
                return true
            } else if goal2.targetDate != nil {
                return false
            } else {
                return goal1.createdTime > goal2.createdTime
            }
        }
        
        /// 已完成：完成日越新排越上面。
        static func sortCompletedGoals(_ goal1: Goal, _ goal2: Goal) -> Bool {
            // completedGoals 濾的條件就是「有完成日」，這裡的 nil 不會發生。
            let date1 = goal1.finishDate ?? .distantPast
            let date2 = goal2.finishDate ?? .distantPast
            if date1 == date2 {
                return goal1.createdTime > goal2.createdTime
            }
            return date1 > date2
        }
    }
    
    enum Action {
        case addGoalButtonTapped
        case goalForm(PresentationAction<GoalFormFeature.Action>)
        case goal(IdentifiedActionOf<GoalFeature>)
        case alert(PresentationAction<Alert>)
        
        /// 寫入雲端失敗。一定要讓使用者看到，否則 Firestore 回滾之後畫面會無聲跳回舊值。
        case writeFailed(any Error)
        
        enum Alert: Equatable {
            case confirmDelete(Goal.ID)
        }
    }
    
    @Dependency(\.goalsRepository) var goalsRepository
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addGoalButtonTapped:
                state.goalForm = GoalFormFeature.State(mode: .add)
                return .none
                
            case let .goalForm(.presented(.delegate(.saveGoal(goal)))):
                state.goals.updateOrAppend(goal)
                state.goalForm = nil
                return .run { _ in
                    try await goalsRepository.saveGoal(goal)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case .goalForm(.presented(.cancelButtonTapped)):
                state.goalForm = nil
                return .none
                
            case .goalForm:
                return .none
                
            case let .goal(.element(id: id, action: .delegate(.saveGoal(goal)))):
                state.goals[id: id] = goal
                return .run { _ in
                    try await goalsRepository.saveGoal(goal)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case let .goal(.element(id: _, action: .delegate(.updateGoalDetails(goal)))):
                // forEach 是就地改子狀態，goal 就是 state.goals 裡那一筆，這裡只負責寫回雲端。
                return .run { _ in
                    try await goalsRepository.updateGoalDetails(goal)
                } catch: { error, send in
                    await send(.writeFailed(error))
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
                
            case let .writeFailed(error):
                state.alert = .writeFailed(error)
                return .none
                
            case .alert(.dismiss):
                return .none
                
            case let .alert(.presented(.confirmDelete(id))):
                state.goals.remove(id: id)
                return .run { _ in
                    try await goalsRepository.deleteGoal(id)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
            }
        }
        .ifLet(\.$goalForm, action: \.goalForm) {
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
