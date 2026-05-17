//
//  TodayTaskCardView.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

public struct TodayTaskCardView: View {
    public var title: String
    public var isDone: Bool
    public var sourceGoalName: String?
    public var onToggle: () -> Void
    
    public init(title: String, isDone: Bool, sourceGoalName: String? = nil, onToggle: @escaping () -> Void) {
        self.title = title
        self.isDone = isDone
        self.sourceGoalName = sourceGoalName
        self.onToggle = onToggle
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isDone ? .blue : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isDone ? .gray : .black)
                    .strikethrough(isDone)
                
                if let sourceGoalName = sourceGoalName {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 10))
                        Text("來自「\(sourceGoalName)」")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}
