//
//  GoalsModel.swift
//  AfterWork
//
//  Created by NY on 2026/3/21.
//

import Foundation
import IdentifiedCollections
import ComposableArchitecture

/// 目標
@ObservableState
struct Goal: Equatable, Identifiable, Codable, Sendable {
    typealias ID = String
    /// ID
    let id: String
    /// 標題
    var title: String
    /// 目標描述
    var description: String?
    /// 預計完成時間
    var targetDate: Date?
    /// 完成時間
    var finishDate: Date?
    /// 細項
    var details: IdentifiedArrayOf<GoalItem>
    /// 建立時間
    var createdTime: Date
    /// 編輯時間
    var updatedTime: Date
    
    init(
        id: String,
        title: String,
        description: String? = nil,
        targetDate: Date? = nil,
        finishDate: Date? = nil,
        details: IdentifiedArrayOf<GoalItem> = [],
        createdTime: Date,
        updatedTime: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.finishDate = finishDate
        self.details = details
        self.createdTime = createdTime
        self.updatedTime = updatedTime
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case targetDate
        case finishDate
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
        self.finishDate = try container.decodeIfPresent(Date.self, forKey: .finishDate)
        let detailsArray = try container.decodeIfPresent([GoalItem].self, forKey: .details) ?? []
        self.details = IdentifiedArray(uniqueElements: detailsArray)
        self.createdTime = try container.decode(Date.self, forKey: .createdTime)
        self.updatedTime = try container.decode(Date.self, forKey: .updatedTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(targetDate, forKey: .targetDate)
        try container.encodeIfPresent(finishDate, forKey: .finishDate)
        let detailsArray = Array(details)
        try container.encode(detailsArray, forKey: .details)
        try container.encode(createdTime, forKey: .createdTime)
        try container.encode(updatedTime, forKey: .updatedTime)
    }
    
    // MARK: 自訂
    /// 只存在本地、不會寫進 Firestore 的編輯狀態。
    ///
    /// 收成一包是為了讓 AppFeature 收到 listener 推播時可以整包接回去（`goal.local = previous.local`）。
    /// 以前是逐欄保留，之後有人加新欄位卻忘了加進保留清單，症狀會是
    /// 「使用者打到一半的字被遠端推播洗掉」—— 很難查。收成一包就不可能漏。
    struct LocalEditing: Equatable, Sendable {
        /// 是否顯示新增細項輸入列
        var isAddingItem: Bool = false
        /// 新增細項輸入內容
        var newItemTitle: String = ""
        /// 記憶展開狀態以觸發畫面機制 (Optional 屬性享有 Swift 免宣告豁免權，不用寫入任何 init)
        var expanded: Bool?
    }
    var local = LocalEditing()
    /// 是否展開
    var isExpanded: Bool {
        get { local.expanded ?? UserInfoManager.shared.isGoalExpanded(for: id, default: details.isEmpty) }
        set {
            local.expanded = newValue
            UserInfoManager.shared.setGoalExpanded(newValue, for: id)
        }
    }
    /// 進度
    var progress: Double {
        guard !details.isEmpty else { return 0 }
        
        let done = details.filter { $0.isDone }.count
        
        return Double(done) / Double(details.count)
    }
    /// 是否完成。以 `finishDate` 為準，它是雲端上唯一的完成事實。
    var isCompleted: Bool {
        finishDate != nil
    }
    /// 細項是否全部勾完。沒有細項的目標不算完成，不然新建的空目標一開頭就在已完成區。
    private var isAllDetailsDone: Bool {
        !details.isEmpty && details.allSatisfy(\.isDone)
    }
    
    /// 依細項的完成狀態決定 `finishDate`：全部勾完就蓋上完成日，只要有一項退回未完成就清掉。
    mutating func syncFinishDate(now: Date) {
        guard isAllDetailsDone else {
            finishDate = nil
            return
        }
        if finishDate == nil {
            finishDate = now
        }
    }
    
    /// 依「未完成在前、已完成在後」重排細項，並把 `order` 重新編號成連續值。
    /// 
    /// 勾選細項有兩個入口 -
    /// 目標分頁的 `GoalFeature.itemChecked`、今天分頁的 `TodayFeature.toggleGoalItem`
    mutating func sortDetails() {
        var items = Array(details)
        items.sort {
            if $0.isDone == $1.isDone {
                return $0.order < $1.order
            }
            return !$0.isDone && $1.isDone
        }
        for index in items.indices {
            items[index].order = index
        }
        details = IdentifiedArray(uniqueElements: items)
    }
}

/// 目標 - 細項
struct GoalItem: Equatable, Identifiable, Codable, Sendable {
    /// ID
    let id: String
    /// 細項標題
    var title: String
    /// 是否完成
    var isDone: Bool
    /// 加入今日的時間。nil 代表沒被拉進今天分頁
    var addedToTodayTime: Date?
    /// 順序
    var order: Int
    /// 建立時間
    var createdTime: Date
    /// 編輯時間
    var updatedTime: Date
}
