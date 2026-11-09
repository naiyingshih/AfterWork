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
                CheckCircle(isDone: isDone, uncheckedColor: Color.label.opacity(0.3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(isDone ? "已完成" : "未完成")
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    // 刪除線的粗細跟著字重走，沒有參數可調；完成時降字重讓線細一點。
                    .font(.system(size: 16, weight: isDone ? .medium : .bold))
                    .foregroundColor(isDone ? Color.labelTertiary : Color.label)
                    .strikethrough(isDone, color: Color.labelTertiary)
                
                if let sourceGoalName = sourceGoalName {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 10))
                        Text("來自「\(sourceGoalName)」")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.main)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}
