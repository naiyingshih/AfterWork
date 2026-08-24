//
//  HabitTagView.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

public struct HabitTagView: View {
    public let title: String
    public let type: HabitType
    public let isCompleted: Bool
    public let streak: Int
    public let onTap: () -> Void
    public let onLongPress: () -> Void

    public init(title: String, type: HabitType, isCompleted: Bool, streak: Int, onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) {
        self.title = title
        self.type = type
        self.isCompleted = isCompleted
        self.streak = streak
        self.onTap = onTap
        self.onLongPress = onLongPress
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .multilineTextAlignment(.center)

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
        .frame(width: 90, height: 90)
        .background(isCompleted ? type.fillColor : Color.card)
        .foregroundColor(isCompleted ? Color.onFill : Color.label)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isCompleted ? .clear : Color.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        // 用手勢而不是 Button：長按手勢疊在 Button 上，放開手時連 Button 的短按都會一起觸發，
        // 變成「想編輯卻順手把習慣打勾」。兩個手勢直接掛在同一個 View 上才會互斥。
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            onLongPress()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "編輯") {
            onLongPress()
        }
    }
}
