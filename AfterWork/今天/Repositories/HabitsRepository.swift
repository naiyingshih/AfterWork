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
    var fetchHabits: () async throws -> [Habit]
    var saveHabit: (Habit) async throws -> Void
    var deleteHabit: (Habit.ID) async throws -> Void
    var updateHabit: (Habit) async throws -> Void
}

extension HabitsRepository: DependencyKey {
    static let liveValue = Self(
        fetchHabits: {
            let snapshot = try await Firestore.firestore().collection("habits").getDocuments()
            return try snapshot.documents.compactMap { doc in
                try? doc.data(as: Habit.self)
            }
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
            var updated = habit
            updated.updatedTime = Date()
            try await Firestore.firestore()
                .collection("habits")
                .document(updated.id)
                .setData(from: updated)
        }
    )
}

extension DependencyValues {
    var habitsRepository: HabitsRepository {
        get { self[HabitsRepository.self] }
        set { self[HabitsRepository.self] = newValue }
    }
}
