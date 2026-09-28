//
//  CalendarFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI
import IdentifiedCollections

/// 成就卡上的一筆完成任務。今日任務與目標細項在畫面上長得一樣，統一成同一個型別。
struct AchievementTask: Identifiable, Equatable {
    let id: String
    let title: String
    let isDone: Bool
}

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        /// 預設選中今天，讓 AchievementCardView 一進畫面就顯示今天的成就。
        ///
        /// 這兩個 `Date()` 是「初始畫面要停在哪」的種子值，不是business logic —— 會寫進資料的時間
        /// 一律走 `@Dependency(\.date)`（見 reducer 的 `now`）。種子值放在 State 的預設值裡，
        /// 是為了讓 `AppFeature.State()` 在任何情境（含測試）都能無條件建起來；改成讀 dependency
        /// 的話，測試裡建 State 就會踩到未實作的 `date` 而失敗。測試要控時間就直接指定這兩個欄位。
        var selectedDate: Date? = Date()
        /// 一律正規化到月初，才能當作 ScrollView paging 的 id。
        var currentMonth: Date = CalendarFeature.startOfMonth(Date())
        
        /// 跟今天分頁共用同一份資料：那邊勾完任務，這裡的成就卡當下就是新的，
        /// 不用等下面 onAppear 的 Firestore 再抓一次才換字。
        @Shared(.habits) var allHabits: IdentifiedArrayOf<Habit> = []
        @Shared(.todayTasks) var allTasks: IdentifiedArrayOf<TodayTask> = []
        @Shared(.goals) var allGoals: IdentifiedArrayOf<Goal> = []
        
        // MARK: 成就卡與日曆格子的衍生資料
        // 這幾段以前寫在 AchievementCardView / DayCellView 裡。「選了某天 -> 那天有哪些成就」
        // 是這個 app 的核心邏輯，放在 View 裡就寫不了測試。
        
        /// 選中那天的任務：自己建的今日任務，加上那天從目標拉進來的細項。
        var achievementTasks: [AchievementTask] {
            guard let selectedDate else { return [] }
            let calendar = Calendar.current
            
            var result = allTasks
                .filter { calendar.isDate($0.createdTime, inSameDayAs: selectedDate) }
                .map { AchievementTask(id: $0.id, title: $0.title, isDone: $0.isDone) }
            
            for goal in allGoals {
                for detail in goal.details {
                    guard let addedTime = detail.addedToTodayTime,
                          calendar.isDate(addedTime, inSameDayAs: selectedDate) else { continue }
                    result.append(
                        AchievementTask(id: detail.id, title: detail.title, isDone: detail.isDone)
                    )
                }
            }
            return result
        }
        
        /// 選中那天執行過的習慣。
        var achievementHabits: [Habit] {
            guard let selectedDate else { return [] }
            let calendar = Calendar.current
            return allHabits.filter { habit in
                habit.completedDates.contains { calendar.isDate($0, inSameDayAs: selectedDate) }
            }
        }
        
        /// 每一天執行過哪些配色的習慣，給日曆格子上的小圓點用。
        /// 依 `HabitStyle` 去重而不是依類型：兩個都是「其他」但自訂色不同的習慣要各畫一顆點。
        /// 做成 dictionary 是因為一頁有 42 格：逐格去掃全部習慣是 42 × N 次日期比對，
        /// 而且每次重繪都要重來一遍。呼叫端請讀一次存成區域變數再分給各格。
        var habitStylesByDay: [Date: Set<HabitStyle>] {
            let calendar = Calendar.current
            var result: [Date: Set<HabitStyle>] = [:]
            for habit in allHabits {
                for date in habit.completedDates {
                    result[calendar.startOfDay(for: date), default: []].insert(habit.style)
                }
            }
            return result
        }
    }
    
    enum Action {
        case selectDate(Date)
        case previousMonth
        case nextMonth
        case setMonth(Date)
    }
    
    @Dependency(\.date.now) var now
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .selectDate(date):
                state.selectedDate = date
                return .none
                
            case .previousMonth:
                if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    state.selectedDate = Self.defaultSelectedDate(for: newMonth, now: now)
                }
                return .none
                
            case .nextMonth:
                if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    state.selectedDate = Self.defaultSelectedDate(for: newMonth, now: now)
                }
                return .none
                
            case let .setMonth(date):
                let month = Self.startOfMonth(date)
                guard month != state.currentMonth else { return .none }
                state.currentMonth = month
                state.selectedDate = Self.defaultSelectedDate(for: month, now: now)
                return .none
            }
        }
    }
    
    static func startOfMonth(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }
    
    /// 本月 -> 預設選今天；其他月份 -> 不選，AchievementCardView 隱藏直到使用者點日期。
    private static func defaultSelectedDate(for month: Date, now: Date) -> Date? {
        Calendar.current.isDate(month, equalTo: now, toGranularity: .month) ? now : nil
    }
}
