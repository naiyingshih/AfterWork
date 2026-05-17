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
}

public struct Habit: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public var title: String
    public var icon: String
    public var type: HabitType
    public var repeatRule: RepeatRule
    public var streak: Int
    public var completedDates: [Date]
    public var createdTime: Date
    public var endDate: Date?
    public var updatedTime: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        icon: String = "⭐",
        type: HabitType,
        repeatRule: RepeatRule = .daily,
        streak: Int = 0,
        completedDates: [Date] = [],
        createdTime: Date = Date(),
        endDate: Date? = nil,
        updatedTime: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.type = type
        self.repeatRule = repeatRule
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
    
    public func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDayDate = calendar.startOfDay(for: date)
        let startOfDayCreated = calendar.startOfDay(for: createdTime)
        
        if startOfDayDate < startOfDayCreated { return false }
        if let end = endDate, startOfDayDate > calendar.startOfDay(for: end) { return false }
        
        let components = calendar.dateComponents([.day, .month, .year], from: startOfDayCreated, to: startOfDayDate)
        
        switch repeatRule {
        case .daily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: startOfDayDate) == calendar.component(.weekday, from: startOfDayCreated)
        case .monthly:
            return calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: startOfDayCreated)
        case let .custom(amount, unit):
            switch unit {
            case .day:
                guard let days = components.day else { return false }
                return days % amount == 0
            case .week:
                guard let days = components.day else { return false }
                let sameWeekday = calendar.component(.weekday, from: startOfDayDate) == calendar.component(.weekday, from: startOfDayCreated)
                return sameWeekday && ((days / 7) % amount == 0)
            case .month:
                guard let months = components.month else { return false }
                let sameDay = calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: startOfDayCreated)
                return sameDay && (months % amount == 0)
            case .year:
                guard let years = components.year else { return false }
                let sameDay = calendar.component(.day, from: startOfDayDate) == calendar.component(.day, from: startOfDayCreated)
                let sameMonth = calendar.component(.month, from: startOfDayDate) == calendar.component(.month, from: startOfDayCreated)
                return sameDay && sameMonth && (years % amount == 0)
            }
        }
    }
}
