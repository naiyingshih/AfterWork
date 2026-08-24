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
        self.repeatRule = repeatRule
        self.repeatRuleStartDate = repeatRuleStartDate
        self.streak = streak
        self.completedDates = completedDates
        self.createdTime = createdTime
        self.endDate = endDate
        self.updatedTime = updatedTime
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
