//
//  PillButton.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

/// 「今天」頁區塊標題旁的白色膠囊按鈕。
struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.label)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color.card, in: Capsule())
                .shadow(color: .black.opacity(0.05), radius: 2)
        }
        .buttonStyle(.plain)
    }
}
