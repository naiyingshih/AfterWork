//
//  TodayView.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

public struct TodayView: View {
    @Bindable var store: StoreOf<TodayFeature>
    
    init(store: StoreOf<TodayFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            List {
                VStack(spacing: 32) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Habits Section
                    habitsSection
                    
                    // MARK: - Tasks Header
                    tasksHeaderSection
                    
                }
                .padding()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Tasks Content
                tasksContentSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationBarHidden(true)
            .background(Color.background.edgesIgnoringSafeArea(.all))
            .onAppear {
                store.send(.refreshToday)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                store.send(.refreshToday)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                store.send(.refreshToday)
            }
            .sheet(item: $store.scope(state: \.habitManage, action: \.habitManage)) { hbStore in
                HabitManageSheet(store: hbStore)
            }
            .sheet(item: $store.scope(state: \.taskSheet, action: \.taskSheet)) { tsStore in
                TodayTaskSheet(store: tsStore)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
    
    // MARK: - Subviews
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        return formatter.string(from: store.today)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currentDateString)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.labelSecondary)
            
            Text("今日行動")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(Color.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var habitsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("習慣養成")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.labelSecondary)
                
                Spacer()
                
                PillButton(title: "+ 新增") {
                    store.send(.addHabitButtonTapped)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(store.habits) { habit in
                        HabitTagView(
                            title: habit.title,
                            style: habit.style,
                            isCompleted: habit.isCompletedToday,
                            streak: habit.streak,
                            onTap: {
                                store.send(.toggleHabit(habit), animation: .default)
                            },
                            onLongPress: {
                                store.send(.editHabitButtonTapped(habit))
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var tasksHeaderSection: some View {
        HStack {
            Text("今日任務")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.labelSecondary)
            
            Spacer()
            
            HStack(spacing: 12) {
                PillButton(title: "+ 建立") {
                    store.send(.addTaskButtonTapped)
                }
                
                PillButton(title: "從目標拉取") {
                    store.send(.pullFromGoalsButtonTapped)
                }
            }
        }
    }
    
    @ViewBuilder
    private var tasksContentSection: some View {
        // Goal Items
        ForEach(store.goalItems) { todayItem in
            TodayTaskCardView(
                title: todayItem.item.title,
                isDone: todayItem.item.isDone,
                sourceGoalName: todayItem.goalTitle,
                onToggle: {
                    store.send(.toggleGoalItem(todayItem), animation: .default)
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    store.send(.deleteGoalItem(todayItem), animation: .default)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("刪除")
                .tint(Color.destructive)
            }
        }
        
        // Standalone Tasks
        ForEach(store.todayTasks) { task in
            TodayTaskCardView(
                title: task.title,
                isDone: task.isDone,
                sourceGoalName: nil,
                onToggle: {
                    store.send(.toggleTask(task), animation: .default)
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    store.send(.deleteTask(task), animation: .default)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("刪除")
                .tint(Color.destructive)
            }
        }
    }
}
