//
//  WriteFailureAlert.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture

extension AlertState {
    /// 寫入 Firestore 失敗時的提示。
    ///
    /// 這個提示不能省：畫面上的變更都是「先寫本地、再送雲端」的樂觀更新，
    /// 而一旦最終寫入失敗，Firestore 會把那筆 pending write 回滾，
    /// snapshot listener 隨即把舊值推回來 —— 使用者看到的會是
    /// 「剛勾好的任務自己取消勾選」，卻沒有任何線索。
    static func writeFailed(_ error: any Error) -> Self {
        AlertState {
            TextState("儲存失敗")
        } actions: {
            ButtonState(role: .cancel) { TextState("確定") }
        } message: {
            TextState("這次的變更沒有存到雲端，畫面會回到原本的狀態。\n\(error.localizedDescription)")
        }
    }
}
