//
//  GoalsModel.swift
//  AfterWork
//
//  Created by NY on 2026/3/21.
//

import Foundation
import IdentifiedCollections
import ComposableArchitecture

@ObservableState
struct Goal: Equatable, Identifiable, Codable {
    typealias ID = String
    /// ID
    let id: String
    /// 標題
    var title: String
    /// 預計完成時間
    var targetDate: Date?
    /// 細項
    var details: IdentifiedArrayOf<GoalItem>
    /// 建立時間
    var createdTime: Date
    /// 編輯時間
    var updatedTime: Date
    /// 是否展開
    var isExpanded: Bool = false
    
    /// 進度
    var progress: Double {
        guard !details.isEmpty else { return 0 }
        
        let done = details.filter { $0.isDone }.count
        
        return Double(done) / Double(details.count)
    }
}

struct GoalItem: Equatable, Identifiable, Codable {
    /// ID
    let id: String
    /// 細項標題
    var title: String
    /// 是否完成
    var isDone: Bool
    /// 是否加入今日
    var isAddedToToday: Bool
    /// 順序
    var order: Int
    /// 建立時間
    var createdTime: Date
    /// 編輯時間
    var updatedTime: Date
}
