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
                    // Month navigation
                    MonthHeaderView(store: store)
                    
                    // Calendar Grid
                    CalendarGridView(store: store)
                        .padding(.horizontal, 4)
                        
                    // Detail Card (成就)
                    if store.selectedDate != nil {
                        AchievementCardView(store: store)
                            .padding(.top, 10)
                    }
                }
                .padding()
            }
            .navigationTitle("回顧")
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - MonthHeaderView
struct MonthHeaderView: View {
    let store: StoreOf<CalendarFeature>
    
    var body: some View {
        HStack {
            Button(action: { store.send(.previousMonth) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                    .padding()
            }
            
            Spacer()
            
            Text(monthYearString(from: store.currentMonth))
                .font(.headline)
                .bold()
            
            Spacer()
            
            Button(action: { store.send(.nextMonth) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
                    .padding()
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
}

// MARK: - CalendarGridView
struct CalendarGridView: View {
    let store: StoreOf<CalendarFeature>
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            // Day of week header
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Grid
            let days = generateDays(for: store.currentMonth)
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        DayCellView(date: date, store: store)
                            .onTapGesture {
                                store.send(.selectDate(date))
                            }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            store.send(.nextMonth)
                        } else if value.translation.width > 50 {
                            store.send(.previousMonth)
                        }
                    }
            )
        }
    }
    
    private func generateDays(for month: Date) -> [Date?] {
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
        
        return days
    }
    
    private func roundToMidday(_ date: Date) -> Date {
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

// MARK: - AchievementCardView
struct AchievementCardView: View {
    let store: StoreOf<CalendarFeature>
    
    var body: some View {
        if let selectedDate = store.selectedDate {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(dateString(from: selectedDate)) 成就")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                // Section 1: Tasks (TodayTask & GoalItem)
                VStack(alignment: .leading, spacing: 12) {
                    let dailyTasks = getTasks(for: selectedDate)
                    let completedCount = dailyTasks.filter { $0.isDone }.count
                
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("完成 \(completedCount) 個任務")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                if !dailyTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(dailyTasks, id: \.id) { task in
                            Text(task.title)
                                .font(.subheadline)
                                .foregroundColor(task.isDone ? .primary : .gray)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    Text("無任務紀錄")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Section 2: Habits
            VStack(alignment: .leading, spacing: 12) {
                let executedHabits = getExecutedHabits(on: selectedDate)
                
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("執行習慣")
                        .font(.subheadline)
                        .bold()
                }
                
                if !executedHabits.isEmpty {
                    WrappingHStack(models: executedHabits) { habit in
                        HStack(spacing: 4) {
                            Text(habit.icon)
                            Text(habit.title)
                                .font(.caption)
                                .bold()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    Text("無習慣紀錄")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        } else {
            EmptyView()
        }
    }
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    // Helper model for unifying Tasks
    struct UnifiedTask: Identifiable {
        let id: String
        let title: String
        let isDone: Bool
    }
    
    func getTasks(for date: Date) -> [UnifiedTask] {
        let calendar = Calendar.current
        var result: [UnifiedTask] = []
        
        // 1. Add TodayTasks
        let specificTasks = store.todayTasks.filter { calendar.isDate($0.createdTime, inSameDayAs: date) }
        result.append(contentsOf: specificTasks.map { UnifiedTask(id: $0.id, title: $0.title, isDone: $0.isDone) })
        
        // 2. Add GoalItems
        for goal in store.goals {
            let details = goal.details.filter { item in
                item.isAddedToToday &&
                (item.addedToTodayTime != nil && calendar.isDate(item.addedToTodayTime!, inSameDayAs: date))
            }
            result.append(contentsOf: details.map { UnifiedTask(id: $0.id, title: $0.title, isDone: $0.isDone) })
        }
        
        return result
    }
    
    func getExecutedHabits(on date: Date) -> [Habit] {
        let calendar = Calendar.current
        return store.habits.filter { habit in
            habit.completedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        }
    }
}

// Simple Wrapping HStack for Habit Tags
struct WrappingHStack<Model, V>: View where Model: Identifiable, V: View {
    let models: [Model]
    let viewGenerator: (Model) -> V
    
    var body: some View {
        // Fallback simple layout: just an HStack wrapped in a ScrollView if needed or simply HStack.
        // For production, a flexible flow layout is better, but since it's just a few habits, 
        // a horizontal scroll view is safe. Let's use it or just HBox.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(models) { model in
                    self.viewGenerator(model)
                }
            }
        }
    }
}

#Preview {
    CalendarView(
        store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        }
    )
}
