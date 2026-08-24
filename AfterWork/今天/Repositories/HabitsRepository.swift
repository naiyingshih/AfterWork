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
    static let liveValue = Self(
        streamHabits: {
            firestoreCollectionStream("habits", as: Habit.self)
        },
        saveHabit: { habit in
            try await Firestore.firestore()
                .collection("habits")
                .document(habit.id)
                .setData(from: habit)
        },
        deleteHabit: { id in
            try await Firestore.firestore()
                .collection("habits")
                .document(id)
                .delete()
        },
        updateHabit: { habit in
            try await Firestore.firestore()
                .collection("habits")
                .document(habit.id)
                .setData(from: habit)
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
