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
        var selectedDate: Date? = nil
        var currentMonth: Date = Date()
        
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
                    state.selectedDate = nil
                }
                return .none
                
            case .nextMonth:
                if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    state.selectedDate = nil
                }
                return .none
                
            case let .setMonth(date):
                state.currentMonth = date
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
}
