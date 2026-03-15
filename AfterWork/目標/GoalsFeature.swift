//
//  GoalsFeature.swift
//  AfterWork
//
//  Created by NY on 2026/3/15.
//

import ComposableArchitecture
import SwiftUI

extension GoalsFeature.State {
    
    static let mock = Self(
        goals: [
            GoalFeature.State(
                id: UUID(),
                title: "學會一首吉他曲",
                items: [
                    GoalItem(id: UUID(), title: "練前奏", isDone: true),
                    GoalItem(id: UUID(), title: "練副歌", isDone: true),
                    GoalItem(id: UUID(), title: "練 solo", isDone: false),
                    GoalItem(id: UUID(), title: "錄完整影片", isDone: false)
                ]
            ),
            
            GoalFeature.State(
                id: UUID(),
                title: "進修 SwiftUI",
                items: [
                    GoalItem(id: UUID(), title: "看 WWDC", isDone: false),
                    GoalItem(id: UUID(), title: "做一個 Demo", isDone: false)
                ]
            )
        ]
    )
}

@Reducer
struct GoalsFeature {
    
    @ObservableState
    struct State: Equatable {
        var goals: IdentifiedArrayOf<GoalFeature.State> = []
    }
    
    enum Action {
        case addGoalButtonTapped
        case goal(id: UUID, action: GoalFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
            case .addGoalButtonTapped:
                return .none
            case let .goal(id, childAction):
                guard var childState = state.goals[id: id] else { return .none }
                let effect = GoalFeature().reduce(into: &childState, action: childAction)
                state.goals[id: id] = childState
                return effect.map { GoalsFeature.Action.goal(id: id, action: $0) }
            }
        }
    }
}
