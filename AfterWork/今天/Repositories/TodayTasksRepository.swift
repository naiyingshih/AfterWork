//
//  TodayTasksRepository.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation
import FirebaseFirestore
import ComposableArchitecture

struct TodayTasksRepository {
    var fetchTasks: () async throws -> [TodayTask]
    var saveTask: (TodayTask) async throws -> Void
    var deleteTask: (TodayTask.ID) async throws -> Void
    var updateTask: (TodayTask) async throws -> Void
}

extension TodayTasksRepository: DependencyKey {
    static let liveValue = Self(
        fetchTasks: {
            let snapshot = try await Firestore.firestore().collection("todayTasks").getDocuments()
            return try snapshot.documents.compactMap { doc in
                try? doc.data(as: TodayTask.self)
            }
        },
        saveTask: { task in
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(task.id)
                .setData(from: task)
        },
        deleteTask: { id in
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(id)
                .delete()
        },
        updateTask: { task in
            var updated = task
            updated.updatedTime = Date()
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(updated.id)
                .setData(from: updated, merge: true)
        }
    )
}

extension DependencyValues {
    var todayTasksRepository: TodayTasksRepository {
        get { self[TodayTasksRepository.self] }
        set { self[TodayTasksRepository.self] = newValue }
    }
}
