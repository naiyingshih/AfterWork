//
//  GoalItemModel.swift
//  AfterWork
//
//  Created by NY on 2026/3/15.
//

import Foundation

struct GoalItem: Equatable, Identifiable {
    let id: UUID
    var title: String
    var isDone: Bool
}
