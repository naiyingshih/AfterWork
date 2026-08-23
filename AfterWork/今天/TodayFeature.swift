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
        var searchText: String = ""
        var habits: IdentifiedArrayOf<Habit> = []
        var todayTasks: IdentifiedArrayOf<TodayTask> = []
        var goalItems: IdentifiedArrayOf<TodayGoalItem> = []
        
        @Presents var habitManage: HabitManageFeature.State?
        @Presents var taskSheet: TodayTaskSheetFeature.State?
        
        init() {}
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        
        case fetchHabitsResponse(Result<[Habit], Error>)
        case fetchTasksResponse(Result<[TodayTask], Error>)
        case fetchGoalsResponse(Result<[Goal], Error>)
        
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
        
        case delegate(Delegate)
        enum Delegate: Equatable {
            case switchToGoals
        }
    }
    
    @Dependency(\.habitsRepository) var habitsRepository
    @Dependency(\.todayTasksRepository) var todayTasksRepository
    @Dependency(\.goalsRepository) var goalsRepository
    
    init() {}
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    async let habitsResult = Result { try await habitsRepository.fetchHabits() }
                    async let tasksResult = Result { try await todayTasksRepository.fetchTasks() }
                    async let goalsResult = Result { try await goalsRepository.fetchGoals() }
                    
                    await send(.fetchHabitsResponse(habitsResult))
                    await send(.fetchTasksResponse(tasksResult))
                    await send(.fetchGoalsResponse(goalsResult))
                }
                
            case let .fetchHabitsResponse(.success(habits)):
                let today = Date()
                let scheduledHabits = habits.filter { $0.isScheduled(on: today) }
                state.habits = IdentifiedArray(uniqueElements: scheduledHabits)
                return .none
            case .fetchHabitsResponse(.failure):
                return .none
                
            case let .fetchTasksResponse(.success(tasks)):
                let calendar = Calendar.current
                let todaysTasks = tasks.filter { calendar.isDateInToday($0.createdTime) }
                state.todayTasks = IdentifiedArray(uniqueElements: todaysTasks)
                return .none
            case .fetchTasksResponse(.failure):
                return .none
                
            case let .fetchGoalsResponse(.success(goals)):
                var items: [TodayGoalItem] = []
                let calendar = Calendar.current
                for goal in goals {
                    for detail in goal.details where detail.isAddedToToday {
                        if let addedTime = detail.addedToTodayTime, calendar.isDateInToday(addedTime) {
                            items.append(TodayGoalItem(item: detail, goalId: goal.id, goalTitle: goal.title))
                        }
                    }
                }
                state.goalItems = IdentifiedArray(uniqueElements: items)
                return .none
            case .fetchGoalsResponse(.failure):
                return .none
                
            case let .toggleHabit(habit):
                var newHabit = habit
                let calendar = Calendar.current
                if newHabit.isCompletedToday {
                    newHabit.completedDates.removeAll { calendar.isDateInToday($0) }
                    newHabit.streak = max(0, newHabit.streak - 1)
                } else {
                    newHabit.completedDates.append(Date())
                    newHabit.streak += 1
                }
                state.habits[id: habit.id] = newHabit
                return .run { [newHabit] send in
                    try? await habitsRepository.updateHabit(newHabit)
                }
                
            case let .toggleTask(task):
                var newTask = task
                newTask.isDone.toggle()
                state.todayTasks[id: task.id] = newTask
                return .run { [newTask] send in
                    try? await todayTasksRepository.updateTask(newTask)
                }
                
            case let .toggleGoalItem(todayItem):
                var newTodayItem = todayItem
                newTodayItem.item.isDone.toggle()
                state.goalItems[id: todayItem.id] = newTodayItem
                
                return .run { [newTodayItem] send in
                    let goals = try await goalsRepository.fetchGoals()
                    if var goal = goals.first(where: { $0.id == newTodayItem.goalId }) {
                        goal.details[id: newTodayItem.id] = newTodayItem.item
                        let detailsArray = Array(goal.details)
                        try await goalsRepository.updateGoalDetails(goal.id, detailsArray)
                    }
                }
                
            case let .deleteTask(task):
                state.todayTasks.remove(id: task.id)
                return .run { send in
                    try? await todayTasksRepository.deleteTask(task.id)
                }
                
            case let .deleteGoalItem(todayItem):
                state.goalItems.remove(id: todayItem.id)
                return .run { send in
                    let goals = try? await goalsRepository.fetchGoals()
                    if var goal = goals?.first(where: { $0.id == todayItem.goalId }) {
                        var updatedItem = todayItem.item
                        updatedItem.isAddedToToday = false
                        updatedItem.addedToTodayTime = nil
                        goal.details[id: todayItem.id] = updatedItem
                        try? await goalsRepository.updateGoalDetails(goal.id, Array(goal.details))
                    }
                }
                
            case .addHabitButtonTapped:
                state.habitManage = HabitManageFeature.State()
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
                if isEditing {
                    if habit.isScheduled(on: Date()) {
                        state.habits[id: habit.id] = habit
                    } else {
                        state.habits.remove(id: habit.id)
                    }
                } else {
                    if habit.isScheduled(on: Date()) {
                        state.habits.append(habit)
                    }
                }
                return .run { [habit, isEditing] send in
                    if isEditing {
                        try? await habitsRepository.updateHabit(habit)
                    } else {
                        try? await habitsRepository.saveHabit(habit)
                    }
                }
                
            case .habitManage(.presented(.cancelButtonTapped)):
                state.habitManage = nil
                return .none
                
            case .habitManage:
                return .none
                
            case let .taskSheet(.presented(.delegate(.saveTask(title)))):
                state.taskSheet = nil
                guard !title.isEmpty else { return .none }
                let newTask = TodayTask(title: title)
                state.todayTasks.append(newTask)
                return .run { [newTask] send in
                    try? await todayTasksRepository.saveTask(newTask)
                }
                
            case .taskSheet(.presented(.cancelButtonTapped)):
                state.taskSheet = nil
                return .none
                
            case .taskSheet:
                return .none
                
            case .binding:
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
    }
}
