//
//  CalendarDerivedStateTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 成就卡與日曆圓點的衍生邏輯以前寫在 View 裡，搬進 State 之後才測得到。
@MainActor
struct CalendarDerivedStateTests {
    
    private let calendar = Calendar.current
    private let day1 = Date(timeIntervalSince1970: 1_700_000_000)   // 2023-11-14
    private var day2: Date { day1.addingTimeInterval(60 * 60 * 24) }
    
    @Test func 成就卡只列出選中那天的任務與目標細項() {
        var state = CalendarFeature.State()
        state.selectedDate = day1
        
        state.$allTasks.withLock {
            $0 = [
                TodayTask(id: "t1", title: "當天的任務", isDone: true, createdTime: day1, updatedTime: day1),
                TodayTask(id: "t2", title: "隔天的任務", createdTime: day2, updatedTime: day2),
            ]
        }
        state.$allGoals.withLock {
            $0 = [
                Goal(
                    id: "g1",
                    title: "讀完一本書",
                    details: [
                        GoalItem(id: "i1", title: "當天拉進來的細項", isDone: false,
                                 addedToTodayTime: day1,
                                 order: 0, createdTime: day1, updatedTime: day1),
                        GoalItem(id: "i2", title: "隔天拉進來的細項", isDone: false,
                                 addedToTodayTime: day2,
                                 order: 1, createdTime: day1, updatedTime: day1),
                        GoalItem(id: "i3", title: "沒拉進今日的細項", isDone: false,
                                 addedToTodayTime: nil,
                                 order: 2, createdTime: day1, updatedTime: day1),
                    ],
                    createdTime: day1,
                    updatedTime: day1
                )
            ]
        }
        
        #expect(state.achievementTasks.map(\.id) == ["t1", "i1"])
        #expect(state.achievementTasks.first?.isDone == true)
    }
    
    @Test func 沒選日期時成就卡沒有內容() {
        var state = CalendarFeature.State()
        state.selectedDate = nil
        state.$allTasks.withLock {
            $0 = [TodayTask(id: "t1", title: "任務", createdTime: day1, updatedTime: day1)]
        }
        
        #expect(state.achievementTasks.isEmpty)
        #expect(state.achievementHabits.isEmpty)
    }
    
    @Test func 日曆圓點按日期分組且同一天的同類型只算一次() {
        var state = CalendarFeature.State()
        state.$allHabits.withLock {
            $0 = [
                Habit(id: "h1", title: "跑步", type: .health,
                      completedDates: [day1, day2], createdTime: day1, updatedTime: day1),
                Habit(id: "h2", title: "散步", type: .health,
                      completedDates: [day1], createdTime: day1, updatedTime: day1),
                Habit(id: "h3", title: "讀書", type: .learning,
                      completedDates: [day1], createdTime: day1, updatedTime: day1),
            ]
        }
        
        let byDay = state.habitTypesByDay
        #expect(byDay[calendar.startOfDay(for: day1)] == [.health, .learning])
        #expect(byDay[calendar.startOfDay(for: day2)] == [.health])
        #expect(byDay[calendar.startOfDay(for: day2.addingTimeInterval(60 * 60 * 24))] == nil)
    }
}
