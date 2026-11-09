//
//  HabitManageTests.swift
//  AfterWorkTests
//
//  Created by NY.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import AfterWork

/// 編輯習慣頁的刪除，以及「其他」類型的自訂顏色。
@MainActor
struct HabitManageTests {
    
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    
    @Test func 刪除要先確認過才會送出委派() async {
        let now = Self.now
        let habit = Habit(id: "h1", title: "跑步", type: .health, createdTime: now, updatedTime: now)
        
        let store = TestStore(initialState: HabitManageFeature.State(habit: habit, isEditing: true, now: now)) {
            HabitManageFeature()
        } withDependencies: {
            $0.date = .constant(now)
            // 這層沒有上層的 presentation，dismiss 只要不爆掉就好。
            $0.dismiss = DismissEffect {}
        }
        
        await store.send(.deleteButtonTapped) {
            $0.alert = AlertState {
                TextState("確定刪除此習慣？")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete) {
                    TextState("是")
                }
                ButtonState(role: .cancel) {
                    TextState("否")
                }
            } message: {
                TextState("已累積的連續天數與完成紀錄會一併刪除。")
            }
        }
        
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
        }
        await store.receive { action in
            guard case let .delegate(.deleteHabit(id)) = action else { return false }
            return id == "h1"
        }
    }
    
    @Test func 確認刪除後收掉alert與關閉sheet會分成兩步() async {
        let now = Self.now
        let habit = Habit(id: "h1", title: "跑步", type: .health, createdTime: now, updatedTime: now)
        
        var todayState = TodayFeature.State()
        todayState.today = now
        todayState.$allHabits.withLock { $0 = [habit] }
        todayState.habitManage = HabitManageFeature.State(habit: habit, isEditing: true, now: now)
        
        // 回顧分頁讀的是同一份共享狀態，刪掉之後那邊也要跟著少一筆。
        let calendarState = CalendarFeature.State()
        #expect(calendarState.allHabits[id: habit.id] != nil)
        
        let deleted = LockIsolated<[Habit.ID]>([])
        let store = TestStore(initialState: todayState) {
            TodayFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.habitsRepository.deleteHabit = { id in deleted.withValue { $0.append(id) } }
        }
        
        await store.send(.habitManage(.presented(.deleteButtonTapped))) {
            $0.habitManage?.alert = AlertState {
                TextState("確定刪除此習慣？")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete) {
                    TextState("是")
                }
                ButtonState(role: .cancel) {
                    TextState("否")
                }
            } message: {
                TextState("已累積的連續天數與完成紀錄會一併刪除。")
            }
        }
        
        // 按下「是」只收掉 alert，sheet 還在。
        await store.send(.habitManage(.presented(.alert(.presented(.confirmDelete))))) {
            $0.habitManage?.alert = nil
        }
        
        await store.receive { action in
            guard case .habitManage(.presented(.delegate(.deleteHabit("h1")))) = action else { return false }
            return true
        } assert: {
            $0.$allHabits.withLock { _ = $0.remove(id: "h1") }
        }
        
        // sheet 是後面這一拍才關掉的；兩件事併成同一次繪製的話 alert 會再閃一次。
        await store.receive { action in
            guard case .habitManage(.dismiss) = action else { return false }
            return true
        } assert: {
            $0.habitManage = nil
        }
        
        #expect(deleted.value == ["h1"])
        #expect(calendarState.allHabits[id: habit.id] == nil)
    }
    
    @Test func 沒設過結束日時預設值是今天而不是建立日() async {
        let now = Self.now
        // 建立日在十天前。預設值停在建立日的話，使用者打開開關直接按儲存就等於設了一個
        // 過去的結束日，習慣當下就從今天分頁消失，而且結束後沒有編輯入口可以救回來。
        let created = now.addingTimeInterval(-10 * 24 * 60 * 60)
        let habit = Habit(id: "h1", title: "跑步", type: .health, createdTime: created, updatedTime: created)

        let state = HabitManageFeature.State(habit: habit, isEditing: true, now: now)

        #expect(state.hasEndDate == false)
        #expect(state.endDate == now)
    }

    @Test func 已經設過結束日就沿用原本那一天() async {
        let now = Self.now
        let created = now.addingTimeInterval(-10 * 24 * 60 * 60)
        let end = now.addingTimeInterval(3 * 24 * 60 * 60)
        let habit = Habit(id: "h1", title: "跑步", type: .health,
                          createdTime: created, endDate: end, updatedTime: created)

        let state = HabitManageFeature.State(habit: habit, isEditing: true, now: now)

        #expect(state.hasEndDate)
        #expect(state.endDate == end)
    }

    @Test func 打開結束日開關直接儲存會寫入今天() async {
        let now = Self.now
        let created = now.addingTimeInterval(-10 * 24 * 60 * 60)
        let habit = Habit(id: "h1", title: "跑步", type: .health, createdTime: created, updatedTime: created)

        let store = TestStore(initialState: HabitManageFeature.State(habit: habit, isEditing: true, now: now)) {
            HabitManageFeature()
        } withDependencies: {
            $0.date = .constant(now)
        }

        await store.send(.binding(.set(\.hasEndDate, true))) {
            $0.hasEndDate = true
        }
        await store.send(.saveButtonTapped) {
            $0.habit.endDate = now
        }
        await store.receive { action in
            guard case let .delegate(.saveHabit(saved)) = action else { return false }
            return saved.endDate == now
        }
        // 結束日是今天 -> 今天仍然排得到，隔天才收掉。
        #expect(store.state.habit.isScheduled(on: now))
        #expect(!store.state.habit.isScheduled(on: now.addingTimeInterval(24 * 60 * 60)))
    }

    @Test func 沒挑顏色的其他類型存檔時補上預設色() async {
        let now = Self.now
        let habit = Habit(id: "h1", title: "冥想", type: .other, createdTime: now, updatedTime: now)
        
        let store = TestStore(initialState: HabitManageFeature.State(habit: habit, now: now)) {
            HabitManageFeature()
        } withDependencies: {
            $0.date = .constant(now)
        }
        
        await store.send(.saveButtonTapped) {
            $0.habit.tagColor = .fallback
        }
        await store.receive { action in
            guard case let .delegate(.saveHabit(saved)) = action else { return false }
            return saved.tagColor == .fallback
        }
    }
    
    @Test func 改回內建類型會清掉自訂顏色() async {
        let now = Self.now
        let habit = Habit(id: "h1", title: "冥想", type: .other, tagColor: .yellow,
                          createdTime: now, updatedTime: now)
        
        let store = TestStore(initialState: HabitManageFeature.State(habit: habit, isEditing: true, now: now)) {
            HabitManageFeature()
        } withDependencies: {
            $0.date = .constant(now)
        }
        
        await store.send(.binding(.set(\.habit.type, .health))) {
            $0.habit.type = .health
        }
        await store.send(.saveButtonTapped) {
            $0.habit.tagColor = nil
        }
        await store.receive { action in
            guard case let .delegate(.saveHabit(saved)) = action else { return false }
            return saved.tagColor == nil
        }
    }
    
    @Test func 自訂顏色不同的其他類型在日曆上各算一顆圓點() {
        let now = Self.now
        var state = CalendarFeature.State()
        state.$allHabits.withLock {
            $0 = [
                Habit(id: "h1", title: "冥想", type: .other, tagColor: .yellow,
                      completedDates: [now], createdTime: now, updatedTime: now),
                Habit(id: "h2", title: "寫日記", type: .other, tagColor: .mint,
                      completedDates: [now], createdTime: now, updatedTime: now),
                // 同色的第二筆只算一顆點。
                Habit(id: "h3", title: "澆花", type: .other, tagColor: .mint,
                      completedDates: [now], createdTime: now, updatedTime: now),
            ]
        }
        
        let day = Calendar.current.startOfDay(for: now)
        #expect(state.habitStylesByDay[day] == [.custom(.yellow), .custom(.mint)])
    }
    
    @Test func 圓點排序固定為內建類型在前自訂色在後() {
        let styles: Set<HabitStyle> = [.custom(.slate), .type(.learning), .custom(.coral), .type(.health)]
        #expect(styles.sorted() == [.type(.health), .type(.learning), .custom(.coral), .custom(.slate)])
    }
}
