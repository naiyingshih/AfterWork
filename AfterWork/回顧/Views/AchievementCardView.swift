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
                    .foregroundColor(Color.labelSecondary)
                    .padding(.bottom, 4)
                
                // Section 1: Tasks (TodayTask & GoalItem)
                VStack(alignment: .leading, spacing: 12) {
                    let dailyTasks = store.achievementTasks
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.main.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Color.main)
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text("完成任務")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(Color.label)
                        Spacer()
                    }
                    
                    if !dailyTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(dailyTasks, id: \.id) { task in
                                Text(task.title)
                                    .font(.subheadline)
                                    .foregroundColor(task.isDone ? Color.label : Color.labelTertiary)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        Text("無任務紀錄")
                            .font(.footnote)
                            .foregroundColor(Color.labelTertiary)
                    }
                }
                
                Divider()
                    .overlay(Color.hairline)
                    .padding(.vertical, 4)
                
                // Section 2: Habits
                VStack(alignment: .leading, spacing: 12) {
                    let executedHabits = store.achievementHabits
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.learningAccent.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "flame")
                                .foregroundColor(Color.learningAccent)
                                .font(.system(size: 18, weight: .medium))
                        }
                        Text("執行習慣")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(Color.label)
                    }
                    
                    if !executedHabits.isEmpty {
                        WrappingHStack(models: executedHabits) { habit in
                            Text(habit.title)
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundColor(Color.onFill)
                                .background(habit.style.fillColor)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("無習慣紀錄")
                            .font(.footnote)
                            .foregroundColor(Color.labelTertiary)
                    }
                }
            }
            .padding(20)
            .background(Color.card)
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
