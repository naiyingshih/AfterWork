//
//  HabitTagView.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

public struct HabitTagView: View {
    public let title: String
    public let style: HabitStyle
    public let isCompleted: Bool
    public let streak: Int
    public let onTap: () -> Void
    public let onLongPress: () -> Void

    /// 觸發長按震動用。`sensoryFeedback` 是看 trigger 值有沒有變，所以這裡用次數而不是 Bool。
    @State private var longPressCount = 0

    public init(title: String, style: HabitStyle, isCompleted: Bool, streak: Int, onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) {
        self.title = title
        self.style = style
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
            .background(isCompleted ? Color.onFill.opacity(0.15) : style.accentColor.opacity(0.15))
            .cornerRadius(12)
            .foregroundColor(isCompleted ? Color.onFill : style.accentColor)
        }
        .frame(width: 90, height: 90)
        .background(isCompleted ? style.fillColor : Color.card)
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
        // 長按沒有視覺上的「按下去了」回饋，只靠手感告訴使用者手勢成立了
        // —— 跟系統長按格狀項目叫出選單時的那下一樣。
        .onLongPressGesture(minimumDuration: 0.4) {
            longPressCount += 1
            onLongPress()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: longPressCount)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "編輯") {
            onLongPress()
        }
    }
}
