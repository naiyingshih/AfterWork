//
//  CheckCircle.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

/// 任務與目標細項共用的圓形勾選框。只負責外觀，無障礙名稱與狀態由外層的 Button 提供。
struct CheckCircle: View {
    let isDone: Bool
    var size: CGFloat = 24
    var uncheckedColor: Color = Color.main

    var body: some View {
        ZStack {
            Circle()
                .fill(isDone ? Color.checkFill : Color.clear)
            Circle()
                .strokeBorder(isDone ? Color.main : uncheckedColor, lineWidth: 1.5)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(Color.main)
            }
        }
        .frame(width: size, height: size)
        // 未勾選時圓內是透明填色，不補點擊形狀的話只剩外環點得到。
        .contentShape(Circle())
    }
}
