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
    /// 目標描述
    var description: String?
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
    
    init(
        id: String,
        title: String,
        description: String? = nil,
        targetDate: Date? = nil,
        details: IdentifiedArrayOf<GoalItem> = [],
        createdTime: Date,
        updatedTime: Date,
        isExpanded: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.details = details
        self.createdTime = createdTime
        self.updatedTime = updatedTime
        self.isExpanded = isExpanded
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case targetDate
        case details
        case createdTime
        case updatedTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        let detailsArray = try container.decodeIfPresent([GoalItem].self, forKey: .details) ?? []
        self.details = IdentifiedArray(uniqueElements: detailsArray)
        self.createdTime = try container.decode(Date.self, forKey: .createdTime)
        self.updatedTime = try container.decode(Date.self, forKey: .updatedTime)
        
        // 畫面的展開狀態：從本地 UserDefaults 讀取（不在 Firebase 留下紀錄）
        self.isExpanded = UserDefaults.standard.bool(forKey: "expanded-\(self.id)")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(targetDate, forKey: .targetDate)
        let detailsArray = Array(details)
        try container.encode(detailsArray, forKey: .details)
        try container.encode(createdTime, forKey: .createdTime)
        try container.encode(updatedTime, forKey: .updatedTime)
    }
    
    // MARK: - 自訂
    /// 目前正在編輯的細項 ID（若為 nil 代表沒有正在新增或編輯）
    var editingItemId: String? = nil
    
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
