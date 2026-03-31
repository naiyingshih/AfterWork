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
                ForEachStore(
                    store.scope(state: \.goals, action: \.goal)
                ) { goalStore in
                    GoalCardView(store: goalStore)
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("目標")
            .onAppear {
                store.send(.onAppear)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
        .scrollDismissesKeyboard(.immediately)
        .overlay(alignment: .bottomTrailing) {
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                store.send(.addGoalButtonTapped)
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if let formStore = store.scope(state: \.goalForm, action: \.goalForm) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            store.send(.goalForm(.cancelButtonTapped))
                        }
                    
                    GoalFormView(store: formStore)
                        .frame(maxHeight: 500)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .padding(24)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .toolbar(store.goalForm != nil ? .hidden : .visible, for: .tabBar)
    }
}
