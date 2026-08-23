//
//  AchievementCardView.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

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
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text("完成任務")
                            .font(.subheadline)
                            .bold()
                        Spacer()
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
            .background(Color(.secondarySystemGroupedBackground))
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(models) { model in
                    self.viewGenerator(model)
                }
            }
        }
    }
}
