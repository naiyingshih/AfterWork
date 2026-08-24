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
    
    // Local states for custom picker if enum has associated values since it is tricky to bind
    @State private var selectedRepeatType: String = "每天"
    @State private var customAmount: Int = 1
    @State private var customUnit: RepeatRuleUnit = .day
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    
    let repeatTypes = ["每天", "每週", "每月", "自訂"]
    
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
                    
                    Picker("重複規則", selection: $selectedRepeatType) {
                        ForEach(repeatTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .onChange(of: selectedRepeatType) { oldValue, newValue in
                        switch newValue {
                        case "每天": store.send(.binding(.set(\.habit.repeatRule, .daily)))
                        case "每週": store.send(.binding(.set(\.habit.repeatRule, .weekly)))
                        case "每月": store.send(.binding(.set(\.habit.repeatRule, .monthly)))
                        case "自訂": store.send(.binding(.set(\.habit.repeatRule, .custom(amount: customAmount, unit: customUnit))))
                        default: break
                        }
                    }
                    
                    if selectedRepeatType == "自訂" {
                        HStack {
                            Picker("數量", selection: $customAmount) {
                                ForEach(1...30, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            
                            Picker("單位", selection: $customUnit) {
                                ForEach(RepeatRuleUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                        .onChange(of: customAmount) { oldValue, newValue in
                            store.send(.binding(.set(\.habit.repeatRule, .custom(amount: newValue, unit: customUnit))))
                        }
                        .onChange(of: customUnit) { oldValue, newValue in
                            store.send(.binding(.set(\.habit.repeatRule, .custom(amount: customAmount, unit: newValue))))
                        }
                    }
                    
                    Toggle("設定結束日期", isOn: $hasEndDate)
                        .onChange(of: hasEndDate) { oldValue, newValue in
                            store.send(.binding(.set(\.habit.endDate, newValue ? endDate : nil)))
                        }
                    
                    if hasEndDate {
                        DatePicker("結束日期", selection: $endDate, displayedComponents: .date)
                            .onChange(of: endDate) { oldValue, newValue in
                                store.send(.binding(.set(\.habit.endDate, newValue)))
                            }
                    }
                }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
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
            .onAppear {
                if let end = store.habit.endDate {
                    hasEndDate = true
                    endDate = end
                }
                
                switch store.habit.repeatRule {
                case .daily: selectedRepeatType = "每天"
                case .weekly: selectedRepeatType = "每週"
                case .monthly: selectedRepeatType = "每月"
                case let .custom(amount, unit):
                    selectedRepeatType = "自訂"
                    customAmount = amount
                    customUnit = unit
                }
            }
        }
    }
}

