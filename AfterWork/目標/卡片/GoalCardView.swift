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
                        .foregroundColor(Color.label)
                    
                    Spacer()
                    
                    Button {
                        store.send(.toggleExpanded)
                    } label: {
                        Image(systemName: store.isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color.labelSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack(spacing: 8) {
                    // 自繪進度條：ProgressView 的底軌是系統色，無法換成色票
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.hairline)
                            Capsule()
                                .fill(Color.main)
                                .frame(width: geo.size.width * store.progress)
                        }
                    }
                    .frame(height: 5)
                    Text("\(Int(round(store.progress * 100)))%")
                        .font(.subheadline)
                        .foregroundColor(Color.labelSecondary)
                }
                
                HStack {
                    if let date = store.finishDate {
                        Text("完成日：\(DateFormatter.yyyyMMdd.string(from: date))")
                            .font(.caption)
                            .foregroundColor(Color.labelSecondary)
                    }
                    Spacer()
                    if let date = store.targetDate {
                        Text("預計完成日：\(DateFormatter.yyyyMMdd.string(from: date))")
                            .font(.caption)
                            .foregroundColor(Color.labelSecondary)
                    }
                }
                
                if store.isExpanded && store.description?.isEmpty == false {
                    Divider()
                        .overlay(Color.hairline)
                    Text(store.description ?? "")
                        .font(.subheadline)
                        .foregroundColor(Color.labelSecondary)
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
                        HStack {
                            Button {
                                store.send(.itemChecked(id: item.id, !item.isDone))
                            } label: {
                                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                    .foregroundColor(item.isDone ? Color.main : Color.labelTertiary)
                                    .imageScale(.large)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(item.title)
                                .strikethrough(item.isDone, color: Color.labelTertiary)
                                .foregroundColor(item.isDone ? Color.labelTertiary : Color.label)
                            
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
                            .tint(Color.main)
                        }
                    }
                    .onMove { source, destination in
                        store.send(.moveItems(source, destination))
                    }
                }
                
                if store.isAddingItem {
                    HStack {
                        TextField(
                            "輸入細項",
                            text: Binding(
                                get: { store.newItemTitle },
                                set: { store.send(.newItemTitleChanged($0)) }
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
                        .foregroundColor(Color.labelSecondary)
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("儲存") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            store.send(.saveItemButtonTapped)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.main)
                        .disabled(store.newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                } else {
                    Button {
                        store.send(.addItemButtonTapped)
                    } label: {
                        Label("新增細項", systemImage: "plus")
                            .foregroundColor(Color.main)
                    }
                }
            }
        }
    }
}
