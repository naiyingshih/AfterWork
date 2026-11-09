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
    /// 直接用 `.white` 在深色模式的 main 上對比不足，換成會跟著模式翻轉的 `background`。
    static var onMain: Color { Color.background }

    /// 輸入框與 chip 的底色。設計稿裡跟分隔線是同一個色（#E7E7E7）。
    static var fieldBackground: Color { Color.hairline }
}

// MARK: - 習慣配色
/// 內建三種類型用色票（Assets.xcassets/Colors），「其他」用下面這組固定色。
extension HabitStyle {

    /// 大面積填色用的粉彩色（兩個模式同值）。
    /// 文字請一律搭配 `Color.onFill`，不要用 `Color.label`——
    /// label 會隨模式翻轉成淺色，疊在同樣淺的粉彩上只剩 1.1~1.6:1。
    var fillColor: Color {
        switch self {
        case .type(.health): return Color.health
        case .type(.chores): return Color.chores
        case .type(.learning): return Color.learning
        // `.other` 一律走 `.custom`（見 `Habit.style`），這裡只是讓 switch 完整。
        case .type(.other): return HabitTagColor.fallback.fillColor
        case let .custom(color): return color.fillColor
        }
    }

    /// 前景色（小圖示、日曆圓點）。淺色模式為加深版本、深色模式為提亮版本，
    /// 因為原始粉彩色畫在白色卡片上對比太低，小圖示幾乎看不見。
    var accentColor: Color {
        switch self {
        case .type(.health): return Color.healthAccent
        case .type(.chores): return Color.choresAccent
        case .type(.learning): return Color.learningAccent
        case .type(.other): return HabitTagColor.fallback.accentColor
        case let .custom(color): return color.accentColor
        }
    }
}

/// 「其他」類型的自訂色票，色值以 Figma 的 Habit Tag 元件為準。
///
/// 色值直接寫在程式裡而不是拆成 12 個 colorset：色值跟對比數字放在一起才看得出為什麼是這個值。
///
/// 對比（用跟內建三色同一套基準算）：
/// - `fillColor` 對 `Color.onFill`(#344E41)：4.8~7.6:1
/// - 淺色 `accentColor` 對 `Color.card`(#FFFFFF)：2.9~5.0:1。yellow 只有 2.9:1，是設計稿的值
/// - 深色 `accentColor` 對深色 `Color.card`(#3A5A40)：4.1~6.5:1
///
/// 深色模式的 accent 直接用填色本身，跟 `choresAccent` / `learningAccent` 的作法一致。
extension HabitTagColor {

    var fillColor: Color { Color(hex: hexes.fill) }

    var accentColor: Color {
        Color(light: Color(hex: hexes.accentLight), dark: Color(hex: hexes.fill))
    }

    private var hexes: (fill: String, accentLight: String) {
        switch self {
        case .coral:  return ("F3C3B5", "A68379")
        case .mint:   return ("9DDFC6", "388568")
        case .sky:    return ("A3BDF5", "4A72A1")
        case .indigo: return ("CDBFEF", "8D80AC")
        case .yellow: return ("F5EDAE", "A39960")
        case .slate:  return ("D6D6D7", "8A8A8C")
        }
    }
}

// MARK: - 色值工具
private extension Color {

    /// "RRGGBB" 十六進位字串。只給上面那組寫死的色票用，不解析外部輸入。
    init(hex: String) {
        let value = UInt32(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// 跟著深淺模式翻轉的動態色。colorset 以外的色值要分模式時用這個。
    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}
