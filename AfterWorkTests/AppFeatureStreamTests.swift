//
//  AppFeatureStreamTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 資料只在 AppFeature 訂閱一次，Firestore 推什麼進來就散給各分頁。
@MainActor
struct AppFeatureStreamTests {
    
    @Test func 任務推播會灌進共享狀態讓今天與回顧一起看到() async {
        let (habits, _) = AsyncStream.makeStream(of: [Habit].self)
        let (tasks, tasksContinuation) = AsyncStream.makeStream(of: [TodayTask].self)
        let (goals, _) = AsyncStream.makeStream(of: [Goal].self)
        
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.habitsRepository.streamHabits = { habits }
            $0.todayTasksRepository.streamTasks = { tasks }
            $0.goalsRepository.streamGoals = { goals }
        }
        
        let subscription = await store.send(.task)
        
        let task = TodayTask(title: "倒垃圾")
        tasksContinuation.yield([task])
        
        await store.receive(\.tasksUpdated) {
            $0.$allTasks.withLock { $0 = [task] }
        }
        // 同一份資料，兩個分頁都看得到。
        #expect(store.state.todayFeature.todayTasks[id: task.id] == task)
        #expect(store.state.calendarFeature.allTasks[id: task.id] == task)
        
        await subscription.cancel()
    }
    
    @Test func 目標推播不會洗掉正在輸入中的細項() async {
        let goal = Goal(id: "g1", title: "讀完一本書", createdTime: Date(), updatedTime: Date())
        
        var initialState = AppFeature.State()
        var editing = goal
        editing.local.isAddingItem = true
        editing.local.newItemTitle = "第一章"
        initialState.goalsFeature.goals = [editing]
        
        let (habits, _) = AsyncStream.makeStream(of: [Habit].self)
        let (tasks, _) = AsyncStream.makeStream(of: [TodayTask].self)
        let (goals, goalsContinuation) = AsyncStream.makeStream(of: [Goal].self)
        
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.habitsRepository.streamHabits = { habits }
            $0.todayTasksRepository.streamTasks = { tasks }
            $0.goalsRepository.streamGoals = { goals }
        }
        
        let subscription = await store.send(.task)
        
        // 另一台裝置改了標題，listener 推了一份新的下來。
        var renamed = goal
        renamed.title = "讀完兩本書"
        goalsContinuation.yield([renamed])
        
        await store.receive(\.goalsUpdated) {
            $0.$allGoals.withLock { $0 = [renamed] }
            var expected = renamed
            expected.local.isAddingItem = true
            expected.local.newItemTitle = "第一章"
            $0.goalsFeature.goals = [expected]
        }
        
        await subscription.cancel()
    }
}
