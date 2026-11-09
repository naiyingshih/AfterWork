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
    
    /// DatePicker 的非 optional binding。
    /// 不用 `Binding($store.targetDate)`，因為它的 getter 是強制解包；
    /// 清除日期後 SwiftUI 移除 DatePicker 前還會再讀一次，解包 nil 會 crash。
    private var targetDateBinding: Binding<Date> {
        Binding(
            get: { store.targetDate ?? Date() },
            set: { newValue in
                guard store.targetDate != nil else { return }
                store.targetDate = newValue
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("目標標題", text: $store.title)
                        .foregroundColor(Color.label)
                    if store.targetDate != nil {
                        HStack {
                            DatePicker(
                                "預計完成日期",
                                selection: targetDateBinding,
                                displayedComponents: .date
                            )
                            Button {
                                store.send(.clearTargetDateTapped)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.labelSecondary)
                            }
                            // Form 的列預設會把整列當成一顆按鈕，不指定 borderless 的話點日期也會清空
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Button {
                            store.send(.setTargetDateTapped)
                        } label: {
                            HStack {
                                Text("預計完成日期")
                                    .foregroundColor(Color.label)
                                Spacer()
                                Text("設定日期")
                                    .foregroundColor(Color.labelSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.card)
                
                Section(header: Text("目標描述").foregroundColor(Color.labelSecondary)) {
                    TextEditor(text: $store.description)
                        .frame(minHeight: 100)
                        .foregroundColor(Color.label)
                        .scrollContentBackground(.hidden)
                }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.background)
            .navigationTitle(store.mode == .add ? "新增目標" : "編輯目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundColor(Color.labelSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.mode == .add ? "建立目標" : "儲存") {
                        store.send(.saveButtonTapped)
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color.main)
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
