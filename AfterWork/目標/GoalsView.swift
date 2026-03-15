//
//  GoalsView.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

struct GoalsView: View {
    @Bindable var store: StoreOf<GoalsFeature>
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEachStore(
                        store.scope(state: \.goals, action: \.goal)
                    ) { goalStore in
                        GoalCardView(store: goalStore)
                    }
                }
                .padding()
            }
            
            .navigationTitle("目標")
            
            .overlay(alignment: .bottomTrailing) {
                Button {
                    store.send(.addGoalButtonTapped)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.blue)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}

#Preview {
    GoalsView(
        store: Store(
            initialState: .mock,
            reducer: { GoalsFeature() }
        )
    )
}
