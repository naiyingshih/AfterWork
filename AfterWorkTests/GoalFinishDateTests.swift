//
//  GoalFinishDateTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 完成日（`finishDate`）是雲端上唯一的「這個目標完成了」事實：
/// 勾完最後一個細項時寫進 Firestore，退回未完成時刪掉，已完成／未完成分組看的就是它。
@MainActor
struct GoalFinishDateTests {
    
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    
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
    
    private static func goal(
        id: String = "g1",
        details: [GoalItem],
        finishDate: Date? = nil
    ) -> Goal {
        Goal(
            id: id,
            title: id,
            finishDate: finishDate,
            details: IdentifiedArray(uniqueElements: details),
            createdTime: now,
            updatedTime: now
        )
    }
    
    /// 剩最後一項沒勾。
    private static var almostDoneGoal: Goal {
        goal(details: [item("a", order: 0, isDone: true), item("b", order: 1)])
    }
    
    /// 已完成，完成日蓋在 `now`。
    private static var finishedGoal: Goal {
        goal(
            details: [item("a", order: 0, isDone: true), item("b", order: 1, isDone: true)],
            finishDate: now
        )
    }
    
    private static func goalsState(_ goals: [Goal]) -> GoalsFeature.State {
        var state = GoalsFeature.State()
        state.goals = IdentifiedArray(uniqueElements: goals)
        return state
    }
    
    private static func todayState(_ goal: Goal) -> TodayFeature.State {
        var state = TodayFeature.State()
        state.today = now
        state.$allGoals.withLock { $0 = [goal] }
        return state
    }
    
    @Test func 勾完最後一個細項才蓋上完成日() async {
        let now = Self.now
        let store = TestStore(initialState: Self.goal(details: [Self.item("a", order: 0), Self.item("b", order: 1)])) {
            GoalFeature()
        } withDependencies: {
            $0.date = .constant(now)
        }
        store.exhaustivity = .off
        
        await store.send(.itemChecked(id: "a", true))
        #expect(store.state.finishDate == nil)
        #expect(store.state.isCompleted == false)
        
        await store.send(.itemChecked(id: "b", true))
        #expect(store.state.finishDate == now)
        #expect(store.state.isCompleted)
    }
    
    @Test func 目標分頁勾完最後一項會把完成日寫進雲端並移到已完成() async {
        let now = Self.now
        let written = LockIsolated<Goal?>(nil)
        
        let store = TestStore(initialState: Self.goalsState([Self.almostDoneGoal])) {
            GoalsFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { written.setValue($0) }
        }
        store.exhaustivity = .off
        
        await store.send(.goal(.element(id: "g1", action: .itemChecked(id: "b", true))))
        await store.finish()
        
        #expect(written.value?.finishDate == now)
        #expect(store.state.completedGoals.map(\.id) == ["g1"])
        #expect(store.state.uncompletedGoals.isEmpty)
    }
    
    @Test func 取消勾選會清掉完成日並寫回雲端() async {
        let now = Self.now
        let written = LockIsolated<Goal?>(nil)
        
        let store = TestStore(initialState: Self.goalsState([Self.finishedGoal])) {
            GoalsFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { written.setValue($0) }
        }
        store.exhaustivity = .off
        #expect(store.state.completedGoals.map(\.id) == ["g1"])
        
        await store.send(.goal(.element(id: "g1", action: .itemChecked(id: "b", false))))
        await store.finish()
        
        // 寫回 nil，repository 才知道要把 Firestore 上的欄位刪掉。
        #expect(written.value?.finishDate == nil)
        #expect(store.state.uncompletedGoals.map(\.id) == ["g1"])
        #expect(store.state.completedGoals.isEmpty)
    }
    
    @Test func 今天分頁勾完最後一項一樣會蓋上完成日() async {
        let now = Self.now
        let written = LockIsolated<Goal?>(nil)
        let todayState = Self.todayState(Self.almostDoneGoal)
        
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.goalsRepository.updateGoalDetails = { written.setValue($0) }
        }
        store.exhaustivity = .off
        
        await store.send(.toggleGoalItem(todayState.goalItems[id: "b"]!))
        await store.finish()
        
        #expect(store.state.allGoals[id: "g1"]?.finishDate == now)
        #expect(written.value?.finishDate == now)
    }
    
    @Test func 在已完成的目標新增細項會退回未完成() async {
        let now = Self.now
        let store = TestStore(initialState: Self.finishedGoal) {
            GoalFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off
        
        await store.send(.addItemButtonTapped)
        await store.send(.newItemTitleChanged("c"))
        await store.send(.saveItemButtonTapped)
        
        #expect(store.state.finishDate == nil)
        #expect(store.state.isCompleted == false)
    }
    
    @Test func 重複同步不會蓋掉原本的完成日() {
        var goal = Self.finishedGoal
        goal.syncFinishDate(now: Self.now.addingTimeInterval(86_400))
        #expect(goal.finishDate == Self.now)
    }
    
    @Test func 分組只看完成日不看細項勾了幾個() {
        let now = Self.now
        let state = Self.goalsState([
            Self.goal(id: "有完成日", details: [Self.item("a", order: 0, isDone: true)], finishDate: now),
            // 細項全勾完但沒有完成日，代表寫入沒成功，就該留在未完成等使用者再勾一次。
            Self.goal(id: "沒有完成日", details: [Self.item("a", order: 0, isDone: true)]),
            Self.goal(id: "進行中", details: [Self.item("a", order: 0), Self.item("b", order: 1, isDone: true)]),
            Self.goal(id: "空目標", details: [])
        ])
        
        #expect(state.completedGoals.map(\.id) == ["有完成日"])
        #expect(Set(state.uncompletedGoals.map(\.id)) == ["沒有完成日", "進行中", "空目標"])
    }
}
