//
//  GoalFeature.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct GoalFeature {
    
    typealias State = Goal
    
    enum Action {
        case toggleExpanded
        case itemChecked(id: GoalItem.ID, Bool)
        case deleteItem(IndexSet)
        case addItemButtonTapped
        case addToToday(id: GoalItem.ID)
    }
    
    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
                
            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none
                
            case let .itemChecked(id, value):
                state.details[id: id]?.isDone = value
                state.updatedTime = Date()
                return .none
                
            case let .deleteItem(indexSet):
                state.details.remove(atOffsets: indexSet)
                state.updatedTime = Date()
                return .none
                
            case .addItemButtonTapped:
                return .none
                
            case let .addToToday(id):
                state.details[id: id]?.isAddedToToday = true
                state.updatedTime = Date()
                return .none
            }
        }
    }
}
