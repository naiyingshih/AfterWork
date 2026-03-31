//
//  GoalFeature.swift
//  AfterWork
//
//  Created by NY.
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
        case itemTitleChanged(id: GoalItem.ID, String)
        case saveItemButtonTapped
        case cancelItemButtonTapped
        case moveItems(IndexSet, Int)
        case addToToday(id: GoalItem.ID)
        case editGoalTapped
        case deleteGoalTapped
        
        case delegate(Delegate)
        
        enum Delegate {
            case saveGoal(Goal)
            case editGoal(Goal)
            case deleteGoal(Goal.ID)
            case updateGoalDetails(Goal.ID, IdentifiedArrayOf<GoalItem>)
        }
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date
    
    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
                
            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none
                
            case let .itemChecked(id, value):
                guard var item = state.details[id: id] else { return .none }
                item.isDone = value
                item.updatedTime = date()
                state.details[id: id] = item
                state.updatedTime = date()
                
                sortDetails(&state)
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case let .deleteItem(indexSet):
                state.details.remove(atOffsets: indexSet)
                state.updatedTime = date()
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case .addItemButtonTapped:
                let newItem = GoalItem(
                    id: uuid().uuidString,
                    title: "",
                    isDone: false,
                    isAddedToToday: false,
                    order: state.details.count,
                    createdTime: date(),
                    updatedTime: date()
                )
                state.details.append(newItem)
                state.editingItemId = newItem.id
                sortDetails(&state)
                return .none
                
            case let .itemTitleChanged(id, text):
                state.details[id: id]?.title = text
                return .none
                
            case .saveItemButtonTapped:
                guard let id = state.editingItemId,
                      let title = state.details[id: id]?.title,
                      !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                
                state.details[id: id]?.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                state.details[id: id]?.updatedTime = date()
                state.editingItemId = nil
                state.updatedTime = date()
                
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case .cancelItemButtonTapped:
                if let id = state.editingItemId {
                    state.details.remove(id: id)
                }
                state.editingItemId = nil
                return .none
                
            case let .moveItems(source, destination):
                var items = Array(state.details)
                items.move(fromOffsets: source, toOffset: destination)
                for index in items.indices {
                    items[index].order = index
                }
                state.details = IdentifiedArrayOf(uniqueElements: items)
                sortDetails(&state)
                
                state.updatedTime = date()
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case let .addToToday(id):
                state.details[id: id]?.isAddedToToday = true
                state.updatedTime = date()
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case .editGoalTapped:
                return .send(.delegate(.editGoal(state)))
                
            case .deleteGoalTapped:
                return .send(.delegate(.deleteGoal(state.id)))
                
            case .delegate:
                return .none
            }
        }
    }
    
    private func sortDetails(_ state: inout State) {
        var items = Array(state.details)
        items.sort {
            if $0.isDone == $1.isDone {
                return $0.order < $1.order
            }
            return !$0.isDone && $1.isDone
        }
        for index in items.indices {
            items[index].order = index
        }
        state.details = IdentifiedArray(uniqueElements: items)
    }
}
