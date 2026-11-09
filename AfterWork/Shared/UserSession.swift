//
//  UserSession.swift
//  AfterWork
//
//  Created by NY.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

/// 取得目前使用者的 uid；還沒登入就在背景做 Firebase 匿名登入，使用者不會看到任何畫面。
///
/// 用 actor + 快取的 Task，是因為 App 一啟動三個 stream 會同時要 uid：
/// 如果各自呼叫 `signInAnonymously()`，會建出三個不同的匿名帳號，資料就散到不同 uid 底下。
/// 匿名帳號存在 Keychain，下次啟動 `currentUser` 會直接還原，不會換 uid。
actor UserSession {
    static let shared = UserSession()

    private var signInTask: Task<String, Error>?

    func uid() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid {
            return uid
        }
        if let signInTask {
            return try await signInTask.value
        }
        let task = Task {
            try await Auth.auth().signInAnonymously().user.uid
        }
        signInTask = task
        do {
            return try await task.value
        } catch {
            // 失敗（例如第一次啟動就離線）就清掉，下次呼叫重新嘗試。
            signInTask = nil
            throw error
        }
    }
}

/// 目前使用者底下的 collection：`users/{uid}/{name}`。
/// 所有讀寫都要經過這裡，Firestore Rules 才能用 `request.auth.uid == userId` 擋住別人的資料。
func userCollection(_ name: String) async throws -> CollectionReference {
    let uid = try await UserSession.shared.uid()
    return Firestore.firestore()
        .collection("users")
        .document(uid)
        .collection(name)
}
