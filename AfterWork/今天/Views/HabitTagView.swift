//
//  HabitTagView.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

public struct HabitTagView: View {
    public let title: String
    public let icon: String
    public let type: HabitType
    public let isCompleted: Bool
    public let streak: Int
    public let onTap: () -> Void

    public init(title: String, icon: String, type: HabitType, isCompleted: Bool, streak: Int, onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.type = type
        self.isCompleted = isCompleted
        self.streak = streak
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(icon)
                    .font(.system(size: 28))

                Text(title)
                    .font(.system(size: 15, weight: .bold))

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(streak)")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCompleted ? Color.onFill.opacity(0.15) : type.accentColor.opacity(0.15))
                .cornerRadius(12)
                .foregroundColor(isCompleted ? Color.onFill : type.accentColor)
            }
            .frame(width: 90, height: 120)
            .background(isCompleted ? type.fillColor : Color.card)
            .foregroundColor(isCompleted ? Color.onFill : Color.label)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isCompleted ? .clear : Color.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
