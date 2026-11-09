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
                    .tint(Color.labelSecondary)
                    
                    if store.habit.type == .other {
                        tagColorRow
                    }
                    
                    Picker("重複規則", selection: $store.repeatKind) {
                        ForEach(HabitManageFeature.State.RepeatKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .tint(Color.labelSecondary)
                    
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
                        .tint(Color.mainFill)
                    
                    if store.hasEndDate {
                        DatePicker("結束日期", selection: $store.endDate, displayedComponents: .date)
                    }
                }
                .listRowBackground(Color.card)
                
                if store.isEditing {
                    Section {
                        Button(role: .destructive) {
                            store.send(.deleteButtonTapped)
                        } label: {
                            // 整列可點，不要只有文字那幾個字才吃得到點擊。
                            Text("刪除習慣")
                                .frame(maxWidth: .infinity)
                        }
                        .foregroundColor(Color.destructive)
                    }
                    .listRowBackground(Color.card)
                }
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
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
    
    /// 「其他」類型的 tag 顏色。做成一排色塊而不是 ColorPicker —— 見 `HabitTagColor` 的說明。
    private var tagColorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("類型顏色")
            
            // 色塊之間不給固定間距，改成各自平分整列寬度，寬窄螢幕都排得剛好。
            HStack(spacing: 0) {
                ForEach(HabitTagColor.allCases, id: \.self) { color in
                    let isSelected = (store.habit.tagColor ?? .fallback) == color
                    Button {
                        $store.habit.tagColor.wrappedValue = color
                    } label: {
                        Circle()
                            .fill(color.fillColor)
                            .frame(width: 28, height: 28)
                            .overlay {
                                // 選中的勾勾疊在填色上，跟習慣卡片用同一組前景色。
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.onFill)
                                }
                            }
                            .overlay {
                                // 淺色色票彼此不容易分辨，補一圈外框標出選中的那個。
                                if isSelected {
                                    Circle()
                                        .strokeBorder(Color.label, lineWidth: 2)
                                        .padding(-4)
                                }
                            }
                            // 色塊只有 28pt，撐開到 44pt 才好按。
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.displayName)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
