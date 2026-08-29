//
//  TodayFeature.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI
import IdentifiedCollections

struct TodayGoalItem: Equatable, Identifiable {
    var id: String { item.id }
    var item: GoalItem
    var goalId: String
    var goalTitle: String
}

@Reducer
struct TodayFeature {
    @ObservableState
    struct State: Equatable {
        /// 「今天」是哪一天。下面幾個清單都以它為基準篩選；
        /// 直接在計算屬性裡呼叫 `Date()` 的話，跨日時 state 沒有變化，SwiftUI 不會重繪。
        ///
        /// 這裡的 `Date()` 只是種子值，進畫面時 `.refreshToday` 會用 `@Dependency(\.date)` 對時。
        var today: Date = Date()
        
        /// 完整資料放共享狀態，回顧分頁讀的是同一份，這邊一改那邊立刻同步。
        @Shared(.habits) var allHabits: IdentifiedArrayOf<Habit> = []
        @Shared(.todayTasks) var allTasks: IdentifiedArrayOf<TodayTask> = []
        @Shared(.goals) var allGoals: IdentifiedArrayOf<Goal> = []
        
        /// 今天排到的習慣。
        var habits: IdentifiedArrayOf<Habit> {
            IdentifiedArray(uniqueElements: allHabits.filter { $0.isScheduled(on: today) })
        }
        
        /// 今天建立的任務。
        var todayTasks: IdentifiedArrayOf<TodayTask> {
            let calendar = Calendar.current
            return IdentifiedArray(
                uniqueElements: allTasks.filter { calendar.isDate($0.createdTime, inSameDayAs: today) }
            )
        }
        
        /// 今天從目標拉進來的細項。
        ///
        /// 同一個目標底下用「加入今日的時間」排
        /// 細項一勾完就會被 `Goal.sortDetails()` 排到目標卡片的最後面，
        var goalItems: IdentifiedArrayOf<TodayGoalItem> {
            let calendar = Calendar.current
            var items: [TodayGoalItem] = []
            for goal in allGoals {
                let todayDetails = goal.details
                    .filter { detail in
                        guard detail.isAddedToToday, let addedTime = detail.addedToTodayTime else { return false }
                        return calendar.isDate(addedTime, inSameDayAs: today)
                    }
                    .sorted { lhs, rhs in
                        let lhsTime = lhs.addedToTodayTime ?? lhs.createdTime
                        let rhsTime = rhs.addedToTodayTime ?? rhs.createdTime
                        return lhsTime == rhsTime ? lhs.id < rhs.id : lhsTime < rhsTime
                    }
                for detail in todayDetails {
                    items.append(TodayGoalItem(item: detail, goalId: goal.id, goalTitle: goal.title))
                }
            }
            return IdentifiedArray(uniqueElements: items)
        }
        
        @Presents var habitManage: HabitManageFeature.State?
        @Presents var taskSheet: TodayTaskSheetFeature.State?
        @Presents var alert: AlertState<Never>?
        
        init() {}
    }
    
    enum Action {
        /// 進畫面／回到前景／系統跨日通知時對一次時間。
        case refreshToday
        
        case toggleHabit(Habit)
        case toggleTask(TodayTask)
        case toggleGoalItem(TodayGoalItem)
        
        case deleteTask(TodayTask)
        case deleteGoalItem(TodayGoalItem)
        
        case addHabitButtonTapped
        case editHabitButtonTapped(Habit)
        case addTaskButtonTapped
        case pullFromGoalsButtonTapped
        
        case habitManage(PresentationAction<HabitManageFeature.Action>)
        case taskSheet(PresentationAction<TodayTaskSheetFeature.Action>)
        case alert(PresentationAction<Never>)
        
        /// 寫入雲端失敗。一定要讓使用者看到，否則 Firestore 回滾之後畫面會無聲跳回舊值。
        case writeFailed(any Error)
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case switchToGoals
        }
    }
    
    @Dependency(\.habitsRepository) var habitsRepository
    @Dependency(\.todayTasksRepository) var todayTasksRepository
    @Dependency(\.goalsRepository) var goalsRepository
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    
    init() {}
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .refreshToday:
                // 同一天就不要動 state，免得每次進畫面都讓整個列表重算一次。
                guard !Calendar.current.isDate(state.today, inSameDayAs: now) else { return .none }
                state.today = now
                return .none
                
            case let .toggleHabit(habit):
                var newHabit = habit
                let calendar = Calendar.current
                if newHabit.isCompletedToday {
                    newHabit.completedDates.removeAll { calendar.isDateInToday($0) }
                    newHabit.streak = max(0, newHabit.streak - 1)
                } else {
                    newHabit.completedDates.append(now)
                    newHabit.streak += 1
                }
                newHabit.updatedTime = now
                state.$allHabits.withLock { $0[id: habit.id] = newHabit }
                return .run { [newHabit] _ in
                    try await habitsRepository.updateHabit(newHabit)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case let .toggleTask(task):
                var newTask = task
                newTask.isDone.toggle()
                newTask.updatedTime = now
                state.$allTasks.withLock { $0[id: task.id] = newTask }
                return .run { [newTask] _ in
                    try await todayTasksRepository.updateTask(newTask)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case let .toggleGoalItem(todayItem):
                var newItem = todayItem.item
                newItem.isDone.toggle()
                newItem.updatedTime = now
                state.$allGoals.withLock {
                    $0[id: todayItem.goalId]?.details[id: todayItem.id] = newItem
                    // 跟目標分頁的 itemChecked 用同一套規則把已完成的細項排到最後
                    $0[id: todayItem.goalId]?.sortDetails()
                    // 勾完最後一項就蓋上完成日、取消勾選就清掉，跟目標分頁同一套規則。
                    $0[id: todayItem.goalId]?.syncFinishDate(now: now)
                    $0[id: todayItem.goalId]?.updatedTime = now
                }
                
                guard let goal = state.allGoals[id: todayItem.goalId] else { return .none }
                return .run { [goal] _ in
                    try await goalsRepository.updateGoalDetails(goal)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case let .deleteTask(task):
                state.$allTasks.withLock { _ = $0.remove(id: task.id) }
                return .run { _ in
                    try await todayTasksRepository.deleteTask(task.id)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case let .deleteGoalItem(todayItem):
                var updatedItem = todayItem.item
                updatedItem.isAddedToToday = false
                updatedItem.addedToTodayTime = nil
                updatedItem.updatedTime = now
                state.$allGoals.withLock {
                    $0[id: todayItem.goalId]?.details[id: todayItem.id] = updatedItem
                    $0[id: todayItem.goalId]?.updatedTime = now
                }
                
                guard let goal = state.allGoals[id: todayItem.goalId] else { return .none }
                return .run { [goal] _ in
                    try await goalsRepository.updateGoalDetails(goal)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case .addHabitButtonTapped:
                state.habitManage = HabitManageFeature.State(
                    habit: Habit(
                        id: uuid().uuidString,
                        title: "",
                        type: .health,
                        createdTime: now,
                        updatedTime: now
                    )
                )
                return .none
                
            case let .editHabitButtonTapped(habit):
                state.habitManage = HabitManageFeature.State(habit: habit, isEditing: true)
                return .none
                
            case .addTaskButtonTapped:
                state.taskSheet = TodayTaskSheetFeature.State()
                return .none
                
            case .pullFromGoalsButtonTapped:
                return .send(.delegate(.switchToGoals))
                
            case let .habitManage(.presented(.delegate(.saveHabit(habit)))):
                let isEditing = state.habitManage?.isEditing ?? false
                state.habitManage = nil
                var habit = habit
                habit.updatedTime = now
                state.$allHabits.withLock { $0[id: habit.id] = habit }
                return .run { [habit, isEditing] _ in
                    if isEditing {
                        try await habitsRepository.updateHabit(habit)
                    } else {
                        try await habitsRepository.saveHabit(habit)
                    }
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case .habitManage(.presented(.cancelButtonTapped)):
                state.habitManage = nil
                return .none
                
            case .habitManage:
                return .none
                
            case let .taskSheet(.presented(.delegate(.saveTask(title)))):
                state.taskSheet = nil
                guard !title.isEmpty else { return .none }
                let newTask = TodayTask(
                    id: uuid().uuidString,
                    title: title,
                    createdTime: now,
                    updatedTime: now
                )
                state.$allTasks.withLock { _ = $0.append(newTask) }
                return .run { [newTask] _ in
                    try await todayTasksRepository.saveTask(newTask)
                } catch: { error, send in
                    await send(.writeFailed(error))
                }
                
            case .taskSheet(.presented(.cancelButtonTapped)):
                state.taskSheet = nil
                return .none
                
            case .taskSheet:
                return .none
                
            case let .writeFailed(error):
                state.alert = .writeFailed(error)
                return .none
                
            case .alert:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$habitManage, action: \.habitManage) {
            HabitManageFeature()
        }
        .ifLet(\.$taskSheet, action: \.taskSheet) {
            TodayTaskSheetFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
