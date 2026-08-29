//
//  TodayGoalItemFilterTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 「這個細項今天要不要出現在今天分頁」只看 `addedToTodayTime`。
/// 以前還多存一個 `isAddedToToday` 旗標，但它只有加入／移出兩個入口會動，跨日之後沒人收——
/// 拿時間直接比當天就沒有這個問題，這裡測的是跨日真的會自動失效。
@MainActor
struct TodayGoalItemFilterTests {
    
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)      // 2023-11-14
    private static var yesterday: Date { now.addingTimeInterval(-60 * 60 * 24) }
    
    private static func item(id: String, addedToTodayTime: Date?, order: Int = 0) -> GoalItem {
        GoalItem(
            id: id,
            title: id,
            isDone: false,
            addedToTodayTime: addedToTodayTime,
            order: order,
            createdTime: yesterday,
            updatedTime: yesterday
        )
    }
    
    private static func goal(id: String = "g1", details: [GoalItem]) -> Goal {
        Goal(
            id: id,
            title: "讀完一本書",
            details: IdentifiedArray(uniqueElements: details),
            createdTime: yesterday,
            updatedTime: yesterday
        )
    }
    
    @Test func 只列出加入時間落在今天的細項() {
        var state = TodayFeature.State()
        state.today = Self.now
        state.$allGoals.withLock {
            $0 = [
                Self.goal(details: [
                    Self.item(id: "今天加入的", addedToTodayTime: Self.now, order: 0),
                    Self.item(id: "昨天加入的", addedToTodayTime: Self.yesterday, order: 1),
                    Self.item(id: "沒加入過的", addedToTodayTime: nil, order: 2),
                ])
            ]
        }
        
        #expect(state.goalItems.map(\.id) == ["今天加入的"])
    }
    
    @Test func 跨日之後昨天加入的細項會自己從清單消失() async {
        var state = TodayFeature.State()
        // App 一直開著跨過午夜：昨天拉進來的細項還在，也沒人手動移除。
        state.today = Self.yesterday
        state.$allGoals.withLock {
            $0 = [Self.goal(details: [Self.item(id: "昨天加入的", addedToTodayTime: Self.yesterday)])]
        }
        
        let store = TestStore(initialState: state) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(Self.now)
        }
        
        #expect(store.state.goalItems.map(\.id) == ["昨天加入的"])
        
        // 對完時就該不見了，不必另外去把細項的狀態改回來。
        await store.send(.refreshToday) {
            $0.today = Self.now
        }
        
        #expect(store.state.goalItems.isEmpty)
    }
    
    @Test func 從今天分頁移除會清掉加入時間連回顧那天也跟著少一筆() async {
        var state = TodayFeature.State()
        state.today = Self.now
        state.$allGoals.withLock {
            $0 = [Self.goal(details: [Self.item(id: "今天加入的", addedToTodayTime: Self.now)])]
        }
        
        // 回顧分頁看同一份共享資料。
        var calendarState = CalendarFeature.State()
        calendarState.selectedDate = Self.now
        #expect(calendarState.achievementTasks.map(\.id) == ["今天加入的"])
        
        let store = TestStore(initialState: state) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(Self.now)
            $0.goalsRepository.updateGoalDetails = { _ in }
        }
        
        let todayItem = store.state.goalItems[id: "今天加入的"]!
        await store.send(.deleteGoalItem(todayItem)) {
            $0.$allGoals.withLock {
                $0[id: "g1"]?.details[id: "今天加入的"]?.addedToTodayTime = nil
                $0[id: "g1"]?.details[id: "今天加入的"]?.updatedTime = Self.now
                $0[id: "g1"]?.updatedTime = Self.now
            }
        }
        
        #expect(store.state.goalItems.isEmpty)
        #expect(calendarState.achievementTasks.isEmpty)
    }
}
