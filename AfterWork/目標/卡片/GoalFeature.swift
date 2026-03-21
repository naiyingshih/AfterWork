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
    
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: UUID
        var title: String
        var items: IdentifiedArrayOf<GoalItem>
        var isExpanded: Bool = false
        
        var progress: Double {
            guard !items.isEmpty else { return 0 }
            let done = items.filter { $0.isDone }.count
            return Double(done) / Double(items.count)
        }
    }
    
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
                state.items[id: id]?.isDone = value
                return .none
                
            case let .deleteItem(indexSet):
                state.items.remove(atOffsets: indexSet)
                return .none
                
            case .addItemButtonTapped:
                return .none
                
            case .addToToday:
                return .none
            }
        }
    }
}
