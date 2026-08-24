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
    /// 持續推播的任務清單（Firestore snapshot listener）。
    var streamTasks: () -> AsyncStream<[TodayTask]>
    var saveTask: (TodayTask) async throws -> Void
    var deleteTask: (TodayTask.ID) async throws -> Void
    var updateTask: (TodayTask) async throws -> Void
}

extension TodayTasksRepository: DependencyKey {
    static let liveValue = Self(
        streamTasks: {
            firestoreCollectionStream("todayTasks", as: TodayTask.self)
        },
        saveTask: { task in
            let data = try Firestore.Encoder().encode(task)
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(task.id)
                .setData(data)
        },
        deleteTask: { id in
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(id)
                .delete()
        },
        updateTask: { task in
            let data = try Firestore.Encoder().encode(task)
            try await Firestore.firestore()
                .collection("todayTasks")
                .document(task.id)
                .setData(data, merge: true)
        }
    )
}

extension TodayTasksRepository: TestDependencyKey {
    /// 測試裡沒被覆寫就大聲失敗，不要偷偷連上真的 Firestore。
    static let testValue = Self(
        streamTasks: unimplemented("TodayTasksRepository.streamTasks", placeholder: .never),
        saveTask: unimplemented("TodayTasksRepository.saveTask"),
        deleteTask: unimplemented("TodayTasksRepository.deleteTask"),
        updateTask: unimplemented("TodayTasksRepository.updateTask")
    )
    
    /// SwiftUI 預覽用假資料。
    static let previewValue = Self(
        streamTasks: {
            AsyncStream { continuation in
                continuation.yield([
                    TodayTask(id: "t1", title: "整理書桌"),
                    TodayTask(id: "t2", title: "回信", isDone: true),
                ])
            }
        },
        saveTask: { _ in },
        deleteTask: { _ in },
        updateTask: { _ in }
    )
}

extension DependencyValues {
    var todayTasksRepository: TodayTasksRepository {
        get { self[TodayTasksRepository.self] }
        set { self[TodayTasksRepository.self] = newValue }
    }
}
