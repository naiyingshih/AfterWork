//
//  TodayTaskSheet.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI
import ComposableArchitecture

public struct TodayTaskSheet: View {
    @Bindable public var store: StoreOf<TodayTaskSheetFeature>
    
    public init(store: StoreOf<TodayTaskSheetFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("今天想完成什麼？")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                
                TextField("任務名稱", text: $store.taskTitle)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認") {
                        store.send(.confirmButtonTapped)
                    }
                    .fontWeight(.bold)
                    .disabled(store.taskTitle.isEmpty)
                }
            }
        }
    }
}
