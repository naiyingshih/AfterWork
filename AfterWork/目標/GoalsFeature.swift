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
            Goal(
                id: UUID().uuidString,
                title: "學會一首吉他曲",
                targetDate: Date().addingTimeInterval(86400 * 30),
                details: [
                    GoalItem(
                        id: UUID().uuidString,
                        title: "練前奏",
                        isDone: true,
                        isAddedToToday: false,
                        order: 0,
                        createdTime: Date(),
                        updatedTime: Date()
                    ),
                    GoalItem(
                        id: UUID().uuidString,
                        title: "練副歌",
                        isDone: false,
                        isAddedToToday: false,
                        order: 1,
                        createdTime: Date(),
                        updatedTime: Date()
                    )
                ],
                createdTime: Date(),
                updatedTime: Date()
            )
        ]
    )
}

@Reducer
struct GoalsFeature {
    
    @ObservableState
    struct State: Equatable {
        var goals: IdentifiedArrayOf<Goal> = []
    }
    
    enum Action {
        case addGoalButtonTapped
        case goal(id: Goal.ID, action: GoalFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
                
            case .addGoalButtonTapped:
                return .none
                
            case .goal:
                return .none
            }
        }
        .forEach(
            \.goals,
            action: /Action.goal
        ) {
            GoalFeature()
        }
    }
}
