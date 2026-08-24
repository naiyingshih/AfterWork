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
        /// 編輯前的重複規則，用來判斷規則有沒有被改過。只存在記憶體，不會寫進資料庫。
        public var originalRepeatRule: RepeatRule?
        
        public init(habit: Habit = Habit(title: "", type: .health, repeatRule: .daily), isEditing: Bool = false) {
            self.habit = habit
            self.isEditing = isEditing
            self.originalRepeatRule = isEditing ? habit.repeatRule : nil
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
    
    @Dependency(\.date) var date
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                var habit = state.habit
                // 依編輯後的設定直接覆寫規則
                habit.applyEditedRepeatRule(
                    habit.repeatRule,
                    previousRule: state.originalRepeatRule,
                    effectiveFrom: date()
                )
                state.habit = habit
                return .send(.delegate(.saveHabit(habit)))
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
