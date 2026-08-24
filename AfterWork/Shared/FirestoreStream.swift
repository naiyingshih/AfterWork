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
func firestoreCollectionStream<T: Decodable>(
    _ collection: String,
    as type: T.Type
) -> AsyncStream<[T]> {
    AsyncStream { continuation in
        let listener = Firestore.firestore()
            .collection(collection)
            .addSnapshotListener { snapshot, error in
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
        continuation.onTermination = { _ in listener.remove() }
    }
}
