//
//  GoalsView.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

struct GoalsView: View {
    @Bindable var store: StoreOf<GoalsFeature>
    
    var body: some View {
        NavigationStack {
            List {
                if !store.uncompletedGoals.isEmpty {
                    HStack {
                        Text("未完成")
                            .font(.headline)
                            .foregroundColor(Color.labelSecondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    ForEach(
                        store.scope(state: \.uncompletedGoals, action: \.goal)
                    ) { goalStore in
                        GoalCardView(store: goalStore)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowBackground(Color.card)
                            .listRowSeparatorTint(Color.hairline)
                    }
                }
                
                if !store.completedGoals.isEmpty {
                    HStack {
                        Text("已完成")
                            .font(.headline)
                            .foregroundColor(Color.labelSecondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    ForEach(
                        store.scope(state: \.completedGoals, action: \.goal)
                    ) { goalStore in
                        GoalCardView(store: goalStore)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowBackground(Color.card)
                            .listRowSeparatorTint(Color.hairline)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            // FAB 疊在清單上，讓最後一張卡片能捲到 FAB 上方（FAB 56pt + 上下間距 16pt）。
            .contentMargins(.bottom, 72, for: .scrollContent)
            .animation(.default, value: store.goals)
            .navigationTitle("目標")
            .alert($store.scope(state: \.alert, action: \.alert))
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .bottomTrailing) {
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                store.send(.addGoalButtonTapped)
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(Color.onMain)
                    .frame(width: 56, height: 56)
                    .background(Color.main)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if let formStore = store.scope(state: \.goalForm, action: \.goalForm.presented) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            store.send(.goalForm(.dismiss))
                        }
                    
                    GoalFormView(store: formStore)
                        .frame(maxHeight: 420)
                        .background(Color.card)
                        .cornerRadius(20)
                        .padding(24)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .toolbar(store.goalForm != nil ? .hidden : .visible, for: .tabBar)
    }
}
