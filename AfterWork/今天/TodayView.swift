//
//  TodayView.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

struct TodayView: View {
    @Bindable var store: StoreOf<TodayFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Explore Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Search...", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                if !store.searchText.isEmpty {
                    Text("Searching for: \(store.searchText)")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Explore")
        }
    }
}

#Preview {
    TodayView(
        store: Store(initialState: TodayFeature.State()) {
            TodayFeature()
        }
    )
}
