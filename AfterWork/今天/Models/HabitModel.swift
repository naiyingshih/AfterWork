//
//  HabitModel.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation
import ComposableArchitecture

public enum HabitType: String, CaseIterable, Codable, Equatable, Sendable {
    case health = "健康"
    case chores = "家務"
    case learning = "學習"
    /// 不屬於前三種的習慣。顏色不由類型決定，改由使用者從 `HabitTagColor` 挑一個。
    case other = "其他"
}

/// 「其他」類型可以挑的 tag 色票。
///
/// 給固定色票而不是開放任意選色：填色上的文字一律是 `Color.onFill`，
/// 放任選色很容易挑到跟它對比不足的顏色（太亮或太暗都會）。
/// 這裡每個色都先驗過對比 —— 見 `Color+App.swift` 的色值表。
public enum HabitTagColor: String, CaseIterable, Codable, Equatable, Sendable {
    case rose = "玫瑰"
    case coral = "珊瑚"
    case mint = "薄荷"
    case sky = "天藍"
    case indigo = "靛藍"
    case lavender = "薰衣草"
    case plum = "梅紫"
    case slate = "石板"

    /// 選了「其他」但還沒挑顏色時的預設值。中性色，不會跟內建三種類型撞色。
    public static let fallback: HabitTagColor = .slate
}

/// 一個習慣在畫面上的配色身份。
///
/// 內建類型由類型決定；「其他」由使用者挑的色票決定。
/// 日曆圓點要靠它去重 —— 兩個都是「其他」但顏色不同的習慣，得各畫一顆點。
public enum HabitStyle: Hashable, Sendable {
    case type(HabitType)
    case custom(HabitTagColor)

    /// 圓點排序用。內建類型照 `HabitType` 的宣告順序，自訂色接在後面，
    /// 讓同一天的圓點順序每次重繪都一樣。
    public var sortIndex: Int {
        switch self {
        case let .type(type):
            return HabitType.allCases.firstIndex(of: type) ?? 0
        case let .custom(color):
            return HabitType.allCases.count + (HabitTagColor.allCases.firstIndex(of: color) ?? 0)
        }
    }
}

extension HabitStyle: Comparable {
    public static func < (lhs: HabitStyle, rhs: HabitStyle) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }
}

public enum RepeatRuleUnit: String, CaseIterable, Codable, Equatable, Sendable {
    case day = "天"
    case week = "週"
    case month = "月"
    case year = "年"
}

public enum RepeatRule: Codable, Equatable, Sendable {
    case daily
    case weekly
    case monthly
    case custom(amount: Int, unit: RepeatRuleUnit)
    
    public var title: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每週"
        case .monthly: return "每月"
        case .custom: return "自訂"
        }
    }
    
    /// 寫入前的正規化。「自訂 1 天/週/月」跟「每天/每週/每月」是同一件事，
    /// 統一收斂成固定變體，同一種規則就不會在資料裡留下兩種寫法。
    /// （沒有 `.yearly` 變體，所以自訂 1 年維持原樣。）
    public var normalized: RepeatRule {
        guard case let .custom(amount, unit) = self, amount == 1 else { return self }
        switch unit {
        case .day: return .daily
        case .week: return .weekly
        case .month: return .monthly
        case .year: return self
        }
    }
}

public struct Habit: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public var title: String
    public var type: HabitType
    /// 只有 `type == .other` 時才有意義的 tag 顏色。
    /// 舊資料沒有這個欄位（nil），取用時退回 `HabitTagColor.fallback` —— 見 `style`。
    public var tagColor: HabitTagColor?
    public var repeatRule: RepeatRule
    /// 目前這條規則的生效日，同時是計算週期的錨點。
    /// 改規則時移到修改當天，新規則就從那天重新起算。
    /// 舊資料沒有這個欄位（nil），取用時退回建立日 —— 見 `ruleAnchorDate`。
    public var repeatRuleStartDate: Date?
    public var streak: Int
    public var completedDates: [Date]
    public var createdTime: Date
    public var endDate: Date?
    public var updatedTime: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        type: HabitType,
        tagColor: HabitTagColor? = nil,
        repeatRule: RepeatRule = .daily,
        repeatRuleStartDate: Date? = nil,
        streak: Int = 0,
        completedDates: [Date] = [],
        createdTime: Date = Date(),
        endDate: Date? = nil,
        updatedTime: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.tagColor = tagColor
        self.repeatRule = repeatRule
        self.repeatRuleStartDate = repeatRuleStartDate
        self.streak = streak
        self.completedDates = completedDates
        self.createdTime = createdTime
        self.endDate = endDate
        self.updatedTime = updatedTime
    }
    
    /// 這個習慣在畫面上的配色身份（tag 底色、日曆圓點）。
    public var style: HabitStyle {
        type == .other ? .custom(tagColor ?? .fallback) : .type(type)
    }
    
    /// 寫入前的正規化：`tagColor` 只屬於「其他」，
    /// 改成內建類型就清掉，不要在資料裡留下讀不到的殘值。
    public mutating func normalizeTagColor() {
        tagColor = type == .other ? (tagColor ?? .fallback) : nil
    }
    
    public var isCompletedToday: Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDateInToday($0) }
    }
    
    /// 計算週期的錨點。
    public var ruleAnchorDate: Date { repeatRuleStartDate ?? createdTime }
    
    /// 套用編輯後的重複規則：正規化之後直接覆寫，不留歷史。
    /// 只有規則真的跟 `previousRule` 不同才把錨點移到 `effectiveDate` 當天，
    public mutating func applyEditedRepeatRule(
        _ newRule: RepeatRule,
        previousRule: RepeatRule?,
        effectiveFrom effectiveDate: Date
    ) {
        repeatRule = newRule.normalized
        guard let previousRule, previousRule.normalized != repeatRule else { return }
        repeatRuleStartDate = Calendar.current.startOfDay(for: effectiveDate)
    }
    
    public func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDayDate = calendar.startOfDay(for: date)
        let startOfDayCreated = calendar.startOfDay(for: createdTime)
        
        if startOfDayDate < startOfDayCreated { return false }
        if let end = endDate, startOfDayDate > calendar.startOfDay(for: end) { return false }
        
        let anchor = calendar.startOfDay(for: ruleAnchorDate)
        let components = calendar.dateComponents([.day, .month, .year], from: anchor, to: startOfDayDate)
        
        switch repeatRule {
        case .daily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: startOfDayDate) == calendar.component(.weekday, from: anchor)
        case .monthly:
            return calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: anchor)
        case let .custom(amount, unit):
            guard amount > 0 else { return false }
            switch unit {
            case .day:
                guard let days = components.day else { return false }
                return days % amount == 0
            case .week:
                guard let days = components.day else { return false }
                let sameWeekday = calendar.component(.weekday, from: startOfDayDate) == calendar.component(.weekday, from: anchor)
                return sameWeekday && ((days / 7) % amount == 0)
            case .month:
                guard let months = components.month else { return false }
                let sameDay = calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: anchor)
                return sameDay && (months % amount == 0)
            case .year:
                guard let years = components.year else { return false }
                let sameDay = calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: anchor)
                let sameMonth = calendar.component(.month, from: startOfDayDate) == calendar.component(.month, from: anchor)
                return sameDay && sameMonth && (years % amount == 0)
            }
        }
    }
}
