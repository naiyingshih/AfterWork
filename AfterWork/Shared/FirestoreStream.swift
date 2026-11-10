//
//  FirestoreStream.swift
//  AfterWork
//
//  Created by NY.
//

import FirebaseFirestore
import Foundation

/// 把 Firestore collection 的 snapshot listener 包成 `AsyncStream`。
///
/// 用 listener 取代「每次進畫面 getDocuments 一次」有三個好處：
/// 1. 本地寫入會被 Firestore 的 latency compensation 立刻回吐，畫面不用等 server 來回。
/// 2. 其他裝置改的資料會自己推進來。
/// 3. 各分頁不必再各自 onAppear 重抓，訂閱一次就好。
///
/// 單筆解不出來只跳過那一筆（並印出來），不讓一筆壞資料把整個 collection 清空。
/// stream 結束時務必 `listener.remove()`，否則監聽會一直掛著（也會一直計 Firestore 讀取）。
///
/// `collection` 是使用者底下的子集合名稱，實際路徑為 `users/{uid}/{collection}`。
/// 要先拿到 uid（可能要做匿名登入）才能掛 listener，所以包在 Task 裡；
/// 登入失敗（例如離線）就隔幾秒重試，而不是讓 stream 直接結束、畫面永遠空白。
func firestoreCollectionStream<T: Decodable>(
    _ collection: String,
    as type: T.Type
) -> AsyncStream<[T]> {
    AsyncStream { continuation in
        let task = Task {
            var reference: CollectionReference?
            while reference == nil {
                do {
                    reference = try await userCollection(collection)
                } catch {
                    if Task.isCancelled { return }
                    print("Resolve user collection \(collection) failed: \(error)")
                    // 被取消時 sleep 會 throw，直接結束。
                    do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { return }
                }
            }
            guard let reference, !Task.isCancelled else { return }

            let listener = reference.addSnapshotListener { snapshot, error in
                if let error {
                    print("Listen \(collection) failed: \(error)")
                    return
                }
                guard let snapshot else { return }
                continuation.yield(
                    snapshot.documents.compactMap { document in
                        do {
                            return try document.data(as: T.self)
                        } catch {
                            print("Decode \(collection)/\(document.documentID) failed: \(error)")
                            return nil
                        }
                    }
                )
            }
            // 讓 Task 一直活著到 stream 結束，再移除 listener。
            // 不用 sleep(.max)：極端值交給底層計時器可能溢位成「立刻返回」，listener 就會被提早拔掉。
            // 被取消時 sleep 會立刻 throw，迴圈隨即結束。
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 60 * NSEC_PER_SEC)
            }
            listener.remove()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
