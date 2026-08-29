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
    /// 持續推播的目標清單（Firestore snapshot listener）。
    var streamGoals: () -> AsyncStream<[Goal]>
    var saveGoal: (Goal) async throws -> Void
    var deleteGoal: (Goal.ID) async throws -> Void
    /// 勾選／增刪細項後寫回雲端： details、finishDate、updatedTime 三個欄位
    var updateGoalDetails: (Goal) async throws -> Void
}

extension GoalsRepository: DependencyKey {
    static let liveValue = Self(
        streamGoals: {
            firestoreCollectionStream("goals", as: Goal.self)
        },
        saveGoal: { goal in
            let data = try Firestore.Encoder().encode(goal)
            try await Firestore.firestore()
                .collection("goals")
                .document(goal.id)
                .setData(data)
        },
        deleteGoal: { id in
            try await Firestore.firestore()
                .collection("goals")
                .document(id)
                .delete()
        },
        updateGoalDetails: { goal in
            // 將陣列轉換成 Data Map 以相容 Firebase SDK 的特定直寫模式
            let encoder = Firestore.Encoder()
            let detailsData = try goal.details.map { try encoder.encode($0) }
            var data: [String: Any] = [
                "details": detailsData,
                "updatedTime": goal.updatedTime
            ]
            // 退回未完成時把完成日欄位刪掉
            if let finishDate = goal.finishDate {
                data["finishDate"] = finishDate
            } else {
                data["finishDate"] = FieldValue.delete()
            }
            try await Firestore.firestore()
                .collection("goals")
                .document(goal.id)
                .updateData(data)
        }
    )
}

extension GoalsRepository: TestDependencyKey {
    /// 測試裡沒被覆寫就大聲失敗，不要偷偷連上真的 Firestore。
    static let testValue = Self(
        streamGoals: unimplemented("GoalsRepository.streamGoals", placeholder: .never),
        saveGoal: unimplemented("GoalsRepository.saveGoal"),
        deleteGoal: unimplemented("GoalsRepository.deleteGoal"),
        updateGoalDetails: unimplemented("GoalsRepository.updateGoalDetails")
    )
    
    /// SwiftUI 預覽用假資料。
    static let previewValue = Self(
        streamGoals: {
            AsyncStream { continuation in
                continuation.yield([
                    Goal(
                        id: "g1",
                        title: "讀完一本書",
                        details: [],
                        createdTime: Date(timeIntervalSince1970: 1_700_000_000),
                        updatedTime: Date(timeIntervalSince1970: 1_700_000_000)
                    )
                ])
            }
        },
        saveGoal: { _ in },
        deleteGoal: { _ in },
        updateGoalDetails: { _ in }
    )
}

extension DependencyValues {
    var goalsRepository: GoalsRepository {
        get { self[GoalsRepository.self] }
        set { self[GoalsRepository.self] = newValue }
    }
}

