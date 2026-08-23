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
                store.send(.onAppear)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                store.send(.onAppear)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                store.send(.onAppear)
            }
            .sheet(item: $store.scope(state: \.habitManage, action: \.habitManage)) { hbStore in
                HabitManageSheet(store: hbStore)
            }
            .sheet(item: $store.scope(state: \.taskSheet, action: \.taskSheet)) { tsStore in
                TodayTaskSheet(store: tsStore)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        return formatter.string(from: Date())
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
    }
    
    private var habitsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("習慣養成")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.labelSecondary)
                
                Spacer()
                
                Button(action: {
                    store.send(.addHabitButtonTapped)
                }) {
                    Text("新增")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.main)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(store.habits) { habit in
                        HabitTagView(
                            title: habit.title,
                            icon: habit.icon,
                            type: habit.type,
                            isCompleted: habit.isCompletedToday,
                            streak: habit.streak,
                            onTap: {
                                store.send(.toggleHabit(habit), animation: .default)
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
                Button(action: {
                    store.send(.addTaskButtonTapped)
                }) {
                    Text("+ 建立")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.label)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.card)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.05), radius: 2)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    store.send(.pullFromGoalsButtonTapped)
                }) {
                    Text("從目標拉取")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.label)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.card)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.05), radius: 2)
                }
                .buttonStyle(.plain)
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
                    Label("刪除", systemImage: "trash")
                }
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
                    Label("刪除", systemImage: "trash")
                }
            }
        }
    }
}
