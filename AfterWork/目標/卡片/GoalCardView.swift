//
//  GoalCardView.swift
//  AfterWork
//
//  Created by NY.
//

import ComposableArchitecture
import SwiftUI

struct GoalCardView: View {
    
    @Bindable var store: StoreOf<GoalFeature>
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(store.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        store.send(.toggleExpanded)
                    } label: {
                        Image(systemName: store.isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack(spacing: 8) {
                    ProgressView(value: store.progress)
                        .tint(.blue)
                    Text("\(Int(round(store.progress * 100)))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Spacer()
                    if let date = store.targetDate {
                        Text("預計完成日：\(DateFormatter.yyyyMMdd.string(from: date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if store.isExpanded && store.description?.isEmpty == false {
                    Divider()
                    Text(store.description ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .contextMenu {
                Button {
                    store.send(.editGoalTapped)
                } label: {
                    Label("編輯", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    store.send(.deleteGoalTapped)
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
            
            if store.isExpanded {
                if !store.details.isEmpty {
                    ForEach(store.details) { item in
                        if store.editingItemId == item.id {
                            HStack {
                                TextField(
                                    "輸入細項",
                                    text: Binding(
                                        get: { store.details[id: item.id]?.title ?? "" },
                                        set: { store.send(.itemTitleChanged(id: item.id, $0)) }
                                    )
                                )
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    store.send(.saveItemButtonTapped)
                                }
                                
                                Button("取消") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    store.send(.cancelItemButtonTapped)
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .buttonStyle(PlainButtonStyle())
                                
                                Button("儲存") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    store.send(.saveItemButtonTapped)
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .disabled(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        } else {
                            HStack {
                                Button {
                                    store.send(.itemChecked(id: item.id, !item.isDone))
                                } label: {
                                    Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                        .foregroundColor(item.isDone ? .blue : .secondary)
                                        .imageScale(.large)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(item.title)
                                    .strikethrough(item.isDone, color: .secondary)
                                    .foregroundColor(item.isDone ? .secondary : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = store.details.index(id: item.id) {
                                        store.send(.deleteItem(IndexSet(integer: index)))
                                    }
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    store.send(.addToToday(id: item.id))
                                } label: {
                                    Label("加入今天", systemImage: "calendar.badge.plus")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .onMove { source, destination in
                        store.send(.moveItems(source, destination))
                    }
                }
                
                if store.editingItemId == nil {
                    Button {
                        store.send(.addItemButtonTapped)
                    } label: {
                        Label("新增細項", systemImage: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
