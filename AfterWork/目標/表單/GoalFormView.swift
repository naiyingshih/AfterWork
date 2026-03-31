//
//  GoalFormView.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI
import ComposableArchitecture

struct GoalFormView: View {
    @Bindable var store: StoreOf<GoalFormFeature>
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("目標標題", text: $store.title)
                    DatePicker(
                        "預計完成日期",
                        selection: $store.targetDate,
                        displayedComponents: .date
                    )
                }
                
                Section(header: Text("目標描述")) {
                    TextEditor(text: $store.description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(store.mode == .add ? "新增目標" : "編輯目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.mode == .add ? "建立目標" : "儲存") {
                        store.send(.saveButtonTapped)
                    }
                    .disabled(store.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    GoalFormView(
        store: Store(
            initialState: GoalFormFeature.State(mode: .add),
            reducer: { GoalFormFeature() }
        )
    )
}
