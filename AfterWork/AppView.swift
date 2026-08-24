//
//  AppView.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            GoalsView(
                store: store.scope(state: \.goalsFeature, action: \.goal)
            )
            .tabItem {
                Label("目標", systemImage: "target")
            }
            .tag(AppFeature.Tab.goal)
            
            TodayView(
                store: store.scope(state: \.todayFeature, action: \.today)
            )
            .tabItem {
                Label("今天", systemImage: "sun.righthalf.filled")
            }
            .tag(AppFeature.Tab.today)
            
            CalendarView(
                store: store.scope(state: \.calendarFeature, action: \.calendar)
            )
            .tabItem {
                Label("回顧", systemImage: "calendar")
            }
            .tag(AppFeature.Tab.calendar)
        }
        .task { store.send(.task) }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
