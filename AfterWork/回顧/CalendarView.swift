//
//  CalendarView.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

struct CalendarView: View {
    @Bindable var store: StoreOf<CalendarFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar Card (月份切換 + 日期格)
                    VStack(spacing: 12) {
                        MonthHeaderView(
                            month: store.currentMonth,
                            onPrevious: { store.send(.previousMonth, animation: CalendarAnimation.monthChange) },
                            onNext: { store.send(.nextMonth, animation: CalendarAnimation.monthChange) }
                        )
                        CalendarGridView(store: store)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    // Detail Card (成就)：本月預設顯示今天，其他月份要點日期才出現
                    if store.selectedDate != nil {
                        AchievementCardView(store: store)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                )
                            )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("回顧")
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - MonthHeaderView
/// 吃現成的值而不是自己去讀 store，父層 CalendarView 讀 currentMonth 就一定會帶著這裡一起更新。
struct MonthHeaderView: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text(monthYearString(from: month))
                .font(.headline)
                .bold()
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
}

// MARK: - Animations
enum CalendarAnimation {
    /// 點箭頭切換月份（手勢滑動由原生分頁自己處理，不需要自訂動畫）
    static let monthChange: Animation = .easeInOut(duration: 0.28)
    /// 選日期時成就卡的出現
    static let selectDate: Animation = .easeInOut(duration: 0.22)
}

// MARK: - Grid metrics
/// 固定 6 週 x 7 天，讓每一頁高度一致（分頁容器需要確定高度）。
enum CalendarGridMetrics {
    static let rows = 6
    static let cellHeight: CGFloat = 47
    static let rowSpacing: CGFloat = 15
    static let totalCells = rows * 7
    static var height: CGFloat {
        CGFloat(rows) * cellHeight + CGFloat(rows - 1) * rowSpacing
    }
}

// MARK: - CalendarGridView
/// 月份滑動用原生分頁 TabView(.page)：慣性、跟手、橡皮筋、可中斷手勢都由系統提供，
/// 而且 selection binding 會確實回寫（.scrollPosition(id:) 在 iOS 17 + LazyHStack 下會漏事件）。
struct CalendarGridView: View {
    let store: StoreOf<CalendarFeature>
    
    /// 可滑動的月份範圍（今天前後各 5 年）
    private static let monthSpan = 60
    private static let months: [Date] = {
        let calendar = Calendar.current
        let base = CalendarFeature.startOfMonth(Date())
        return (-monthSpan...monthSpan).compactMap {
            calendar.date(byAdding: .month, value: $0, to: base)
        }
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Day of week header
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
            
            TabView(selection: selectedMonth) {
                ForEach(Self.months, id: \.self) { month in
                    MonthGridView(month: month, store: store)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .tag(month)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: CalendarGridMetrics.height)
        }
    }
    
    /// 雙向：滑動 -> setMonth；點箭頭改 currentMonth -> 分頁跟著切。
    private var selectedMonth: Binding<Date> {
        Binding(
            get: { store.currentMonth },
            set: { store.send(.setMonth($0)) }
        )
    }
}

// MARK: - MonthGridView
struct MonthGridView: View {
    let month: Date
    let store: StoreOf<CalendarFeature>
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        let days = Self.generateDays(for: month)
        LazyVGrid(columns: columns, spacing: CalendarGridMetrics.rowSpacing) {
            ForEach(0..<days.count, id: \.self) { index in
                if let date = days[index] {
                    DayCellView(date: date, store: store)
                        .onTapGesture {
                            store.send(.selectDate(date), animation: CalendarAnimation.selectDate)
                        }
                } else {
                    Color.clear
                        .frame(height: CalendarGridMetrics.cellHeight)
                }
            }
        }
    }
    
    /// 固定回傳 42 格（6 週），讓每一頁高度一致，換月時卡片高度不會跳動。
    static func generateDays(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let emptyDaysCount = firstWeekday - 1
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: roundToMidday(month))?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: emptyDaysCount)
        
        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        
        if days.count < CalendarGridMetrics.totalCells {
            days.append(contentsOf: Array(repeating: nil, count: CalendarGridMetrics.totalCells - days.count))
        }
        
        return days
    }
    
    private static func roundToMidday(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    }
}

// MARK: - DayCellView
struct DayCellView: View {
    let date: Date
    let store: StoreOf<CalendarFeature>
    
    var body: some View {
        let calendar = Calendar.current
        let isSelected = store.selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false
        let isToday = calendar.isDateInToday(date)
        
        VStack(spacing: 6) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : (isToday ? Color.gray.opacity(0.15) : Color.clear))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
            
            // Habit dots
            HStack(spacing: 4) {
                let habitTypes = executedHabitTypes(on: date, habits: Array(store.habits))
                
                if habitTypes.contains(.health) {
                    Circle().fill(Color.green).frame(width: 5, height: 5)
                }
                if habitTypes.contains(.learning) {
                    Circle().fill(Color.blue).frame(width: 5, height: 5)
                }
                if habitTypes.contains(.chores) {
                    Circle().fill(Color.orange).frame(width: 5, height: 5)
                }
                
                if habitTypes.isEmpty {
                    Circle().fill(Color.clear).frame(width: 5, height: 5) // Preserve height
                }
            }
        }
        .contentShape(Rectangle())
    }
    
    private func executedHabitTypes(on date: Date, habits: [Habit]) -> Set<HabitType> {
        let calendar = Calendar.current
        var types = Set<HabitType>()
        for habit in habits {
            if habit.completedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                types.insert(habit.type)
            }
        }
        return types
    }
}

#Preview {
    CalendarView(
        store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        }
    )
}
