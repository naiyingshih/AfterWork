//
//  TodayCalendarSyncTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 今天分頁改資料，回顧分頁要當下就是新的（不必等回顧自己重新抓一次 Firestore）。
@MainActor
struct TodayCalendarSyncTests {
    
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    
    @Test func 勾選今日任務後回顧的成就卡立刻拿到完成狀態() async {
        let now = Self.now
        let task = TodayTask(title: "倒垃圾", createdTime: now, updatedTime: now)
        
        var todayState = TodayFeature.State()
        todayState.today = now
        todayState.$allTasks.withLock { $0 = [task] }
        
        // 回顧分頁在切過去之前就已經存在（TabView 會把三個分頁一起建起來）。
        let calendarState = CalendarFeature.State()
        #expect(calendarState.allTasks[id: task.id]?.isDone == false)
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.todayTasksRepository.updateTask = { _ in }
        }
        
        await store.send(.toggleTask(task)) {
            $0.$allTasks.withLock {
                $0[id: task.id]?.isDone = true
                $0[id: task.id]?.updatedTime = now
            }
        }
        
        #expect(calendarState.allTasks[id: task.id]?.isDone == true)
    }
    
    @Test func 勾選習慣後回顧當天就有那筆習慣紀錄() async {
        let now = Self.now
        let habit = Habit(title: "跑步", type: .health, createdTime: now, updatedTime: now)
        
        var todayState = TodayFeature.State()
        todayState.today = now
        todayState.$allHabits.withLock { $0 = [habit] }
        
        let calendarState = CalendarFeature.State()
        #expect(calendarState.allHabits[id: habit.id]?.completedDates.isEmpty == true)
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.habitsRepository.updateHabit = { _ in }
        }
        
        await store.send(.toggleHabit(habit)) {
            $0.$allHabits.withLock {
                $0[id: habit.id]?.completedDates = [now]
                $0[id: habit.id]?.streak = 1
                $0[id: habit.id]?.updatedTime = now
            }
        }
        
        #expect(calendarState.allHabits[id: habit.id]?.completedDates == [now])
    }
    
    @Test func 寫入雲端失敗會跳出提示而不是無聲回滾() async {
        struct SaveFailed: Error {}
        let now = Self.now
        let task = TodayTask(title: "倒垃圾", createdTime: now, updatedTime: now)
        
        var todayState = TodayFeature.State()
        todayState.today = now
        todayState.$allTasks.withLock { $0 = [task] }
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.todayTasksRepository.updateTask = { _ in throw SaveFailed() }
        }
        store.exhaustivity = .off
        
        await store.send(.toggleTask(task))
        await store.receive { action in
            if case .writeFailed = action { return true }
            return false
        }
        
        #expect(store.state.alert != nil)
    }
}
