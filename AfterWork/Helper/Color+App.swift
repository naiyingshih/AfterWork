//
//  Color+App.swift
//  AfterWork
//
//  Created by NY.
//

import SwiftUI

// MARK: - 語意色
/// 色票本身放在 Assets.xcassets/Colors，這裡只補上由色票推導出來的語意色。
///
/// 注意 `labelSecondary` / `labelTertiary` / `onFill` 都是獨立色票（不是在這裡用 opacity 疊出來的）：
/// 深色模式的卡片提亮後，用 opacity 推導會讓次要文字掉到 2.3:1，必須各自指定深淺值。
extension Color {

    /// 疊在 `main` 之上的前景色。
    /// 直接用 `.white` 在深色模式的 main 上對比不足，換成會跟著模式翻轉的 `background`
    /// 兩邊都有 3:1 以上（淺 3.11:1、深 6.20:1）。
    static var onMain: Color { Color.background }

    /// 卡片外框、分隔線。
    static var hairline: Color { Color.label.opacity(0.12) }

    /// 輸入框與 chip 的底色。
    static var fieldBackground: Color { Color.label.opacity(0.08) }
}

// MARK: - 習慣類型色
extension HabitType {

    /// 大面積填色用的粉彩色（兩個模式同值）。
    /// 文字請一律搭配 `Color.onFill`，不要用 `Color.label`——
    /// label 會隨模式翻轉成淺色，疊在同樣淺的粉彩上只剩 1.1~1.6:1。
    var fillColor: Color {
        switch self {
        case .health: return Color.sub
        case .chores: return Color.chores
        case .learning: return Color.learning
        }
    }

    /// 前景色（小圖示、日曆圓點）。淺色模式為加深版本、深色模式為提亮版本，
    /// 因為原始粉彩色畫在米白卡片上只有 1.4:1。
    var accentColor: Color {
        switch self {
        case .health: return Color.healthAccent
        case .chores: return Color.choresAccent
        case .learning: return Color.learningAccent
        }
    }
}
