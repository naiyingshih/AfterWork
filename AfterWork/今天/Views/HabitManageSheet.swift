//
//  HabitManageSheet.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI
import ComposableArchitecture

public struct HabitManageSheet: View {
    @Bindable public var store: StoreOf<HabitManageFeature>
    
    public init(store: StoreOf<HabitManageFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("習慣名稱", text: $store.habit.title)
                } header: {
                    Text("基本設定")
                        .foregroundColor(Color.labelSecondary)
                }
                .listRowBackground(Color.card)
                
                Section {
                    Picker("習慣類型", selection: $store.habit.type) {
                        ForEach(HabitType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("重複規則", selection: $store.repeatKind) {
                        ForEach(HabitManageFeature.State.RepeatKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    
                    if store.repeatKind == .custom {
                        HStack {
                            Picker("數量", selection: $store.customAmount) {
                                ForEach(1...30, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            
                            Picker("單位", selection: $store.customUnit) {
                                ForEach(RepeatRuleUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                    }
                    
                    Toggle("設定結束日期", isOn: $store.hasEndDate)
                    
                    if store.hasEndDate {
                        DatePicker("結束日期", selection: $store.endDate, displayedComponents: .date)
                    }
                }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.background)
            .navigationTitle(store.isEditing ? "編輯習慣" : "新增習慣")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundColor(Color.labelSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        store.send(.saveButtonTapped)
                    }
                    .foregroundColor(Color.main)
                    .disabled(store.habit.title.isEmpty)
                }
            }
        }
    }
}

