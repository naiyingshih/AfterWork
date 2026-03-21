//
//  CalendarView.swift
//  AfterWork
//
//  Created by NY on 2026/1/24.
//

import ComposableArchitecture
import SwiftUI

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Profile Tab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: store.isLoggedIn ? "person.circle.fill" : "person.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(store.isLoggedIn ? .blue : .gray)
                    
                    Text(store.username)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(store.isLoggedIn ? "Logged In" : "Not Logged In")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        if store.isLoggedIn {
                            store.send(.logoutButtonTapped)
                        } else {
                            store.send(.loginButtonTapped)
                        }
                    } label: {
                        Text(store.isLoggedIn ? "Logout" : "Login")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(store.isLoggedIn ? Color.red : Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    CalendarView(
        store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        }
    )
}
