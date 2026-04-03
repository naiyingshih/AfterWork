//
//  GoalsRepository.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation
import FirebaseFirestore
import ComposableArchitecture

struct GoalsRepository {
    var fetchGoals: () async throws -> [Goal]
    var saveGoal: (Goal) async throws -> Void
    var deleteGoal: (Goal.ID) async throws -> Void
    var updateGoalDetails: (Goal.ID, [GoalItem]) async throws -> Void
}

extension GoalsRepository: DependencyKey {
    static let liveValue = Self(
        fetchGoals: {
            let snapshot = try await Firestore.firestore().collection("goals").getDocuments()
            return try snapshot.documents.map { doc in
                try doc.data(as: Goal.self)
            }
        },
        saveGoal: { goal in
            try await Firestore.firestore().collection("goals").document(goal.id).setData(from: goal)
        },
        deleteGoal: { id in
            try await Firestore.firestore().collection("goals").document(id).delete()
        },
        updateGoalDetails: { id, details in
            // 將陣列轉換成 Data Map 以相容 Firebase SDK 的特定直寫模式
            let encoder = Firestore.Encoder()
            let detailsData = try details.map { try encoder.encode($0) }
            try await Firestore.firestore().collection("goals").document(id).updateData([
                "details": detailsData,
                "updatedTime": Date()
            ])
        }
    )
}

extension DependencyValues {
    var goalsRepository: GoalsRepository {
        get { self[GoalsRepository.self] }
        set { self[GoalsRepository.self] = newValue }
    }
}
