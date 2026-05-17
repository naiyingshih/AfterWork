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
        case newItemTitleChanged(String)
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
                
                if state.progress == 1.0 {
                    if state.finishDate == nil {
                        state.finishDate = date()
                    }
                    state.isExpanded = false
                } else {
                    state.finishDate = nil
                }
                
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case let .deleteItem(indexSet):
                state.details.remove(atOffsets: indexSet)
                state.updatedTime = date()
                
                if state.progress == 1.0 && !state.details.isEmpty {
                    if state.finishDate == nil {
                        state.finishDate = date()
                    }
                    state.isExpanded = false
                } else {
                    state.finishDate = nil
                }
                
                return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                
            case .addItemButtonTapped:
                state.isAddingItem = true
                state.newItemTitle = ""
                return .none

            case let .newItemTitleChanged(text):
                state.newItemTitle = text
                return .none
                
            case .saveItemButtonTapped:
                if state.isAddingItem {
                    let title = state.newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return .none }

                    let newItem = GoalItem(
                        id: uuid().uuidString,
                        title: title,
                        isDone: false,
                        isAddedToToday: false,
                        addedToTodayTime: nil,
                        order: state.details.count,
                        createdTime: date(),
                        updatedTime: date()
                    )
                    state.details.append(newItem)
                    sortDetails(&state)

                    state.isAddingItem = false
                    state.newItemTitle = ""
                    state.updatedTime = date()

                    return .send(.delegate(.updateGoalDetails(state.id, state.details)))
                }
                return .none
                
            case .cancelItemButtonTapped:
                state.isAddingItem = false
                state.newItemTitle = ""
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
                state.details[id: id]?.addedToTodayTime = date()
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
