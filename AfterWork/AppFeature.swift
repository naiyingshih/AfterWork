//
//  AppFeature.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
    enum Tab: Hashable {
        case goal
        case today
        case calendar
    }
    
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .goal
        var goalsFeature = GoalsFeature.State()
        var todayFeature = TodayFeature.State()
        var calendarFeature = CalendarFeature.State()
    }
    
    enum Action {
        case tabSelected(Tab)
        case goal(GoalsFeature.Action)
        case today(TodayFeature.Action)
        case calendar(CalendarFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.goalsFeature, action: \.goal) {
            GoalsFeature()
        }
        Scope(state: \.todayFeature, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.calendarFeature, action: \.calendar) {
            CalendarFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
                
            case .goal:
                return .none
                
            case .today(.delegate(.switchToGoals)):
                state.selectedTab = .goal
                return .none
                
            case .today:
                return .none
                
            case .calendar:
                return .none
            }
        }
    }
}
