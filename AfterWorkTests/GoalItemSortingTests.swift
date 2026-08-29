//
//  GoalItemSortingTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 細項有兩個勾選入口（目標分頁的 `itemChecked`、今天分頁的 `toggleGoalItem`），
/// 兩邊排完的順序必須一致，否則從今天分頁勾完切回目標分頁，已完成的細項不會沉到底部。
@MainActor
struct GoalItemSortingTests {
    
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    
    /// 加入今日的時間刻意跟著 `order` 遞增，好驗證今天分頁是照加入時間排、不是照細項順序排。
    private static func item(_ id: String, order: Int, isDone: Bool = false) -> GoalItem {
        GoalItem(
            id: id,
            title: id,
            isDone: isDone,
            isAddedToToday: true,
            addedToTodayTime: now.addingTimeInterval(Double(order)),
            order: order,
            createdTime: now,
            updatedTime: now
        )
    }
    
    private static func goal(_ details: [GoalItem]) -> Goal {
        Goal(
            id: "g1",
            title: "讀完一本書",
            details: IdentifiedArray(uniqueElements: details),
            createdTime: now,
            updatedTime: now
        )
    }
    
    private static var threeItemGoal: Goal {
        goal([item("a", order: 0), item("b", order: 1), item("c", order: 2)])
    }
    
    private static func todayState(with goal: Goal) -> TodayFeature.State {
        var state = TodayFeature.State()
        state.today = now
        state.$allGoals.withLock { $0 = [goal] }
        return state
    }
    
    @Test func 從今天分頁勾選細項會把它排到目標細項的最後面() async {
        let now = Self.now
        let todayState = Self.todayState(with: Self.threeItemGoal)
        let written = LockIsolated<Goal?>(nil)
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { written.setValue($0) }
        }
        store.exhaustivity = .off
        
        await store.send(.toggleGoalItem(todayState.goalItems[id: "a"]!))
        await store.finish()
        
        let details = store.state.allGoals[id: "g1"]!.details
        #expect(details.map(\.id) == ["b", "c", "a"])
        #expect(details.map(\.order) == [0, 1, 2])
        // 新順序要真的寫進 Firestore，目標分頁才會在 listener 推回來時看到同一份。
        #expect(written.value?.details.map(\.id) == ["b", "c", "a"])
    }
    
    @Test func 兩個分頁勾選同一個細項排出來的順序一樣() async {
        let now = Self.now
        
        let goalStore = TestStore(initialState: Self.threeItemGoal) {
            GoalFeature()
        } withDependencies: {
            $0.date = .constant(now)
        }
        goalStore.exhaustivity = .off
        await goalStore.send(.itemChecked(id: "a", true))
        
        let todayState = Self.todayState(with: Self.threeItemGoal)
        let todayStore = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { _ in }
        }
        todayStore.exhaustivity = .off
        await todayStore.send(.toggleGoalItem(todayState.goalItems[id: "a"]!))
        await todayStore.finish()
        
        let fromGoalTab = goalStore.state.details
        let fromTodayTab = todayStore.state.allGoals[id: "g1"]!.details
        #expect(fromGoalTab.map(\.id) == fromTodayTab.map(\.id))
        #expect(fromGoalTab.map(\.order) == fromTodayTab.map(\.order))
        #expect(fromGoalTab.map(\.isDone) == fromTodayTab.map(\.isDone))
    }
    
    @Test func 今天分頁自己的清單不會因為勾選而跳位() async {
        let now = Self.now
        let todayState = Self.todayState(with: Self.threeItemGoal)
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { _ in }
        }
        store.exhaustivity = .off
        
        let before = todayState.goalItems.map(\.id)
        #expect(before == ["a", "b", "c"])
        
        await store.send(.toggleGoalItem(todayState.goalItems[id: "a"]!))
        await store.finish()
        
        // 目標細項已經重排成 b、c、a，但今天分頁照「加入今日的時間」排，畫面上不動。
        #expect(store.state.goalItems.map(\.id) == before)
        #expect(store.state.goalItems[id: "a"]!.item.isDone == true)
    }
}
