//
//  CalendarFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI
import IdentifiedCollections

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        /// 預設選中今天，讓 AchievementCardView 一進畫面就顯示今天的成就。
        var selectedDate: Date? = Date()
        /// 一律正規化到月初，才能當作 ScrollView paging 的 id。
        var currentMonth: Date = CalendarFeature.startOfMonth(Date())
        
        var habits: IdentifiedArrayOf<Habit> = []
        var todayTasks: IdentifiedArrayOf<TodayTask> = []
        var goals: IdentifiedArrayOf<Goal> = []
        
        var isLoading: Bool = false
    }
    
    enum Action {
        case onAppear
        case selectDate(Date)
        case previousMonth
        case nextMonth
        case setMonth(Date)
        
        case fetchHabitsResponse(Result<[Habit], Error>)
        case fetchTasksResponse(Result<[TodayTask], Error>)
        case fetchGoalsResponse(Result<[Goal], Error>)
    }
    
    @Dependency(\.habitsRepository) var habitsRepository
    @Dependency(\.todayTasksRepository) var todayTasksRepository
    @Dependency(\.goalsRepository) var goalsRepository
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    async let habitsResult = Result { try await habitsRepository.fetchHabits() }
                    async let tasksResult = Result { try await todayTasksRepository.fetchTasks() }
                    async let goalsResult = Result { try await goalsRepository.fetchGoals() }
                    
                    await send(.fetchHabitsResponse(habitsResult))
                    await send(.fetchTasksResponse(tasksResult))
                    await send(.fetchGoalsResponse(goalsResult))
                }
                
            case let .selectDate(date):
                state.selectedDate = date
                return .none
                
            case .previousMonth:
                if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    state.selectedDate = Self.defaultSelectedDate(for: newMonth)
                }
                return .none
                
            case .nextMonth:
                if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    state.selectedDate = Self.defaultSelectedDate(for: newMonth)
                }
                return .none
                
            case let .setMonth(date):
                let month = Self.startOfMonth(date)
                guard month != state.currentMonth else { return .none }
                state.currentMonth = month
                state.selectedDate = Self.defaultSelectedDate(for: month)
                return .none
                
            case let .fetchHabitsResponse(.success(habits)):
                state.habits = IdentifiedArray(uniqueElements: habits)
                state.isLoading = false
                return .none
            case .fetchHabitsResponse(.failure):
                state.isLoading = false
                return .none
                
            case let .fetchTasksResponse(.success(tasks)):
                state.todayTasks = IdentifiedArray(uniqueElements: tasks)
                state.isLoading = false
                return .none
            case .fetchTasksResponse(.failure):
                state.isLoading = false
                return .none
                
            case let .fetchGoalsResponse(.success(goals)):
                state.goals = IdentifiedArray(uniqueElements: goals)
                state.isLoading = false
                return .none
            case .fetchGoalsResponse(.failure):
                state.isLoading = false
                return .none
            }
        }
    }
    
    static func startOfMonth(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }
    
    /// 本月 -> 預設選今天；其他月份 -> 不選，AchievementCardView 隱藏直到使用者點日期。
    private static func defaultSelectedDate(for month: Date) -> Date? {
        let today = Date()
        return Calendar.current.isDate(month, equalTo: today, toGranularity: .month) ? today : nil
    }
}
