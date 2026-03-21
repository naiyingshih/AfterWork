//
//  GoalCardView.swift
//  AfterWork
//
//  Created by NY on 2026/3/15.
//

import ComposableArchitecture
import SwiftUI

struct GoalCardView: View {
    
    @Bindable var store: StoreOf<GoalFeature>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(store.title)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    store.send(.toggleExpanded)
                } label: {
                    Image(systemName: store.isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            
            HStack(spacing: 8) {
                ProgressView(value: store.progress)
                Text("\(Int(round(store.progress * 100)))%")
            }
            
            HStack {
                Spacer()
                if let date = store.targetDate {
                    Text("預計完成日：\(DateFormatter.yyyyMMdd.string(from: date))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if store.isExpanded {
                
                ForEach(store.details) { item in
                    HStack {
                        Button(action: {
                            store.send(.itemChecked(id: item.id, !item.isDone))
                        }) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .foregroundColor(item.isDone ? .accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text(item.title)
                            .strikethrough(item.isDone, color: .secondary)
                            .foregroundColor(item.isDone ? .secondary : .primary)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if let index = store.details.index(id: item.id) {
                                store.send(.deleteItem(IndexSet(integer: index)))
                            }
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.send(.addToToday(id: item.id))
                        } label: {
                            Label("加入今天", systemImage: "calendar.badge.plus")
                        }
                    }
                }
                
                Button {
                    store.send(.addItemButtonTapped)
                } label: {
                    Label("新增細項", systemImage: "plus")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(radius: 2)
        )
    }
}
