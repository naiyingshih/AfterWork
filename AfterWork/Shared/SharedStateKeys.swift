//
//  SharedStateKeys.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import IdentifiedCollections

// 今天與回顧看的是同一份資料，各自存一份就會慢半拍：
// 今天勾完任務切到回顧，成就卡要等回顧自己的 onAppear 把 Firestore 抓完才換字。
// 統一改放 in-memory 共享狀態，任一頁寫入，另一頁的畫面立刻跟著更新；
// Firestore 仍是最終來源，只是各頁的 onAppear 從「填自己的 state」變成「回填這份共享快取」。
//
// 這裡一律存「完整清單」，要看哪一段由各頁自己篩（例如今天只顯示今天排到的習慣）。

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<Habit>> {
    /// 全部習慣，不分日期。
    static var habits: Self { .inMemory("habits") }
}

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<TodayTask>> {
    /// 全部任務，不分日期。
    static var todayTasks: Self { .inMemory("todayTasks") }
}

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<Goal>> {
    /// 全部目標，含細項。
    static var goals: Self { .inMemory("goals") }
}
