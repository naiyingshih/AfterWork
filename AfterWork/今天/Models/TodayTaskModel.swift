//
//  TodayTaskModel.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation
import ComposableArchitecture

public struct TodayTask: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public var title: String
    public var isDone: Bool
    public var createdTime: Date
    public var updatedTime: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        isDone: Bool = false,
        createdTime: Date = Date(),
        updatedTime: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdTime = createdTime
        self.updatedTime = updatedTime
    }
}
