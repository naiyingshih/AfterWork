//
//  HabitsRepository.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation
import FirebaseFirestore
import ComposableArchitecture

struct HabitsRepository {
    /// 持續推播的習慣清單（Firestore snapshot listener）。
    var streamHabits: () -> AsyncStream<[Habit]>
    var saveHabit: (Habit) async throws -> Void
    var deleteHabit: (Habit.ID) async throws -> Void
    var updateHabit: (Habit) async throws -> Void
}

extension HabitsRepository: DependencyKey {
    // 寫入一律「自己編碼 + 走 async 的 setData(_:)」，不要用 Codable 版的 setData(from:)。
    // setData(from:) 的 completion 是選填參數，不傳就是同步 throwing —— 加 await 沒有作用，
    // 而且只會在「編碼失敗」時 throw；伺服器拒絕（權限、規則）永遠傳不回來。
    // 那樣的話 Firestore 回滾本地寫入時，畫面會無聲跳回舊值而不會跳提示。
    static let liveValue = Self(
        streamHabits: {
            firestoreCollectionStream("habits", as: Habit.self)
        },
        saveHabit: { habit in
            let data = try Firestore.Encoder().encode(habit)
            try await userCollection("habits")
                .document(habit.id)
                .setData(data)
        },
        deleteHabit: { id in
            try await userCollection("habits")
                .document(id)
                .delete()
        },
        updateHabit: { habit in
            let data = try Firestore.Encoder().encode(habit)
            try await userCollection("habits")
                .document(habit.id)
                .setData(data)
        }
    )
}

extension HabitsRepository: TestDependencyKey {
    /// 測試裡沒被覆寫就大聲失敗，不要偷偷連上真的 Firestore。
    static let testValue = Self(
        streamHabits: unimplemented("HabitsRepository.streamHabits", placeholder: .never),
        saveHabit: unimplemented("HabitsRepository.saveHabit"),
        deleteHabit: unimplemented("HabitsRepository.deleteHabit"),
        updateHabit: unimplemented("HabitsRepository.updateHabit")
    )
    
    /// SwiftUI 預覽用假資料。預設會落到 liveValue，那會在沒有 FirebaseApp.configure() 的
    /// 預覽環境裡直接連線失敗。
    static let previewValue = Self(
        streamHabits: {
            AsyncStream { continuation in
                continuation.yield([
                    Habit(id: "h1", title: "跑步", type: .health, streak: 3),
                    Habit(id: "h2", title: "閱讀", type: .learning, streak: 12),
                ])
            }
        },
        saveHabit: { _ in },
        deleteHabit: { _ in },
        updateHabit: { _ in }
    )
}

extension DependencyValues {
    var habitsRepository: HabitsRepository {
        get { self[HabitsRepository.self] }
        set { self[HabitsRepository.self] = newValue }
    }
}
