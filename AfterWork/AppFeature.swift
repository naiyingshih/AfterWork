//
//  AppFeature.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI
import IdentifiedCollections

@Reducer
struct AppFeature {
    enum Tab: Hashable {
        case goal
        case today
        case calendar
    }
    
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .today
        var goalsFeature = GoalsFeature.State()
        var todayFeature = TodayFeature.State()
        var calendarFeature = CalendarFeature.State()
        
        /// 三份資料只在這裡訂閱一次，寫進共享狀態後各分頁自己讀自己要的那一段。
        @Shared(.habits) var allHabits: IdentifiedArrayOf<Habit> = []
        @Shared(.todayTasks) var allTasks: IdentifiedArrayOf<TodayTask> = []
        @Shared(.goals) var allGoals: IdentifiedArrayOf<Goal> = []
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        /// App 啟動時開始監聽三個 collection，之後資料由 Firestore 主動推進來。
        case task
        case habitsUpdated([Habit])
        case tasksUpdated([TodayTask])
        case goalsUpdated([Goal])
        
        case goal(GoalsFeature.Action)
        case today(TodayFeature.Action)
        case calendar(CalendarFeature.Action)
    }
    
    private enum CancelID { case habits, tasks, goals }
    
    @Dependency(\.habitsRepository) var habitsRepository
    @Dependency(\.todayTasksRepository) var todayTasksRepository
    @Dependency(\.goalsRepository) var goalsRepository
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.goalsFeature, action: \.goal) {
            GoalsFeature()
        }
        Scope(state: \.todayFeature, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.calendarFeature, action: \.calendar) {
            CalendarFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { send in
                        for await habits in habitsRepository.streamHabits() {
                            await send(.habitsUpdated(habits))
                        }
                    }
                    .cancellable(id: CancelID.habits, cancelInFlight: true),
                    
                    .run { send in
                        for await tasks in todayTasksRepository.streamTasks() {
                            await send(.tasksUpdated(tasks))
                        }
                    }
                    .cancellable(id: CancelID.tasks, cancelInFlight: true),
                    
                    .run { send in
                        for await goals in goalsRepository.streamGoals() {
                            await send(.goalsUpdated(goals))
                        }
                    }
                    .cancellable(id: CancelID.goals, cancelInFlight: true)
                )
                
            case let .habitsUpdated(habits):
                state.$allHabits.withLock { $0 = IdentifiedArray(uniqueElements: habits) }
                return .none
                
            case let .tasksUpdated(tasks):
                state.$allTasks.withLock { $0 = IdentifiedArray(uniqueElements: tasks) }
                return .none
                
            case let .goalsUpdated(goals):
                let incoming = IdentifiedArray(uniqueElements: goals)
                state.$allGoals.withLock { $0 = incoming }
                // 目標分頁的 forEach 需要可寫入的儲存屬性，接不上 @Shared，所以另外餵一份。
                // Goal 身上還帶著只存在本地的編輯狀態（見 Goal.LocalEditing），
                // 整份換掉會把使用者打到一半的字洗掉，所以逐筆把那一包接回去。
                let previous = state.goalsFeature.goals
                state.goalsFeature.goals = IdentifiedArray(
                    uniqueElements: incoming
                        .map { goal in
                            guard let local = previous[id: goal.id]?.local else { return goal }
                            var goal = goal
                            goal.local = local
                            return goal
                        }
                        .sorted(by: GoalsFeature.State.sortGoals)
                )
                return .none
                
            case .binding:
                return .none
                
            case .goal:
                return .none
                
            case .today(.delegate(.switchToGoals)):
                state.selectedTab = .goal
                return .none
                
            case .today:
                return .none
                
            case .calendar:
                return .none
            }
        }
    }
}
