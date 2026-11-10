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
        
        /// 重複規則在畫面上被拆成「種類」＋「自訂的數量／單位」三個控制項，
        /// 拆成獨立欄位才綁得動 Picker，儲存時再由 `composedRepeatRule` 組回一個 RepeatRule。
        /// 這幾個值以前是 HabitManageSheet 自己的 @State，靠 onAppear/onChange 雙向手動同步 ——
        /// 同一份資料兩個真相來源，而且規則組裝這段邏輯住在 View 裡沒辦法測。
        public var repeatKind: RepeatKind
        public var customAmount: Int
        public var customUnit: RepeatRuleUnit
        public var hasEndDate: Bool
        public var endDate: Date
        
        @Presents public var alert: AlertState<Action.Alert>?
        
        public enum RepeatKind: String, CaseIterable, Equatable, Sendable {
            case daily = "每天"
            case weekly = "每週"
            case monthly = "每月"
            case custom = "自訂"
        }
        
        /// `now` 由呼叫端（reducer）從 `@Dependency(\.date)` 傳進來，不要在這裡直接 `Date()`：
        /// 結束日預設值會被寫進資料，測試得控得住它。
        public init(habit: Habit, isEditing: Bool = false, now: Date) {
            self.habit = habit
            self.isEditing = isEditing
            self.originalRepeatRule = isEditing ? habit.repeatRule : nil
            
            switch habit.repeatRule {
            case .daily:
                self.repeatKind = .daily
                self.customAmount = 1
                self.customUnit = .day
            case .weekly:
                self.repeatKind = .weekly
                self.customAmount = 1
                self.customUnit = .week
            case .monthly:
                self.repeatKind = .monthly
                self.customAmount = 1
                self.customUnit = .month
            case let .custom(amount, unit):
                self.repeatKind = .custom
                self.customAmount = amount
                self.customUnit = unit
            }
            
            self.hasEndDate = habit.endDate != nil
            // 結束日預設今天
            self.endDate = habit.endDate ?? now
        }
        
        /// 把三個控制項組回 RepeatRule。
        public var composedRepeatRule: RepeatRule {
            switch repeatKind {
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .custom: return .custom(amount: customAmount, unit: customUnit)
            }
        }
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case deleteButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        
        public enum Alert: Equatable {
            case confirmDelete
        }
        
        public enum Delegate: Equatable {
            case saveHabit(Habit)
            case deleteHabit(Habit.ID)
        }
    }
    
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                var habit = state.habit
                // 依編輯後的設定直接覆寫規則
                habit.applyEditedRepeatRule(
                    state.composedRepeatRule,
                    previousRule: state.originalRepeatRule,
                    effectiveFrom: date()
                )
                habit.endDate = state.hasEndDate ? state.endDate : nil
                habit.normalizeTagColor()
                state.habit = habit
                return .send(.delegate(.saveHabit(habit)))
            case .cancelButtonTapped:
                return .none
            case .deleteButtonTapped:
                state.alert = AlertState {
                    TextState("確定刪除此習慣？")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("是")
                    }
                    ButtonState(role: .cancel) {
                        TextState("否")
                    }
                } message: {
                    TextState("已累積的連續天數與完成紀錄會一併刪除。")
                }
                return .none
            case .alert(.presented(.confirmDelete)):
                // 這個 action 本身會把 state.alert 清成 nil，但收掉 alert 跟收掉 sheet
                // 必須分成兩次繪製：兩者同時發生時，SwiftUI 在 sheet 的收合動畫期間
                // 會沿用上一輪的子狀態（alert 還在），alert 就會再閃出來一次。
                // 所以這裡不讓上層直接把 habitManage 設成 nil，改用 dismiss() 隔一拍再關。
                return .run { [id = state.habit.id] send in
                    await send(.delegate(.deleteHabit(id)))
                    await dismiss()
                }
            case .alert:
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
