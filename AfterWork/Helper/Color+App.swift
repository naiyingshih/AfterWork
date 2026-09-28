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

// MARK: - 習慣配色
/// 內建三種類型用色票（Assets.xcassets/Colors），「其他」用下面這組固定色。
extension HabitStyle {

    /// 大面積填色用的粉彩色（兩個模式同值）。
    /// 文字請一律搭配 `Color.onFill`，不要用 `Color.label`——
    /// label 會隨模式翻轉成淺色，疊在同樣淺的粉彩上只剩 1.1~1.6:1。
    var fillColor: Color {
        switch self {
        case .type(.health): return Color.sub
        case .type(.chores): return Color.chores
        case .type(.learning): return Color.learning
        // `.other` 一律走 `.custom`（見 `Habit.style`），這裡只是讓 switch 完整。
        case .type(.other): return HabitTagColor.fallback.fillColor
        case let .custom(color): return color.fillColor
        }
    }

    /// 前景色（小圖示、日曆圓點）。淺色模式為加深版本、深色模式為提亮版本，
    /// 因為原始粉彩色畫在米白卡片上只有 1.4:1。
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

/// 「其他」類型的自訂色票。
///
/// 色值直接寫在程式裡而不是拆成 16 個 colorset：這組色的重點是「都驗過對比」，
/// 色值跟對比數字放在一起才看得出為什麼是這個值。
///
/// 對比（用跟內建三色同一套基準算）：
/// - `fillColor` 對 `Color.onFill`(#344E41)：4.0~5.6:1（內建三色是 4.0~5.7:1）
/// - 淺色 `accentColor` 對 `Color.card`(#F5F3EE)：4.0~5.2:1
/// - 深色 `accentColor` 對深色 `Color.card`(#3A5A40)：3.4~4.8:1
///
/// 深色模式的 accent 直接用填色本身，跟 `choresAccent` / `learningAccent` 的作法一致。
extension HabitTagColor {

    var fillColor: Color { Color(hex: hexes.fill) }

    var accentColor: Color {
        Color(light: Color(hex: hexes.accentLight), dark: Color(hex: hexes.fill))
    }

    private var hexes: (fill: String, accentLight: String) {
        switch self {
        case .rose:     return ("E39FAC", "A3495B")
        case .coral:    return ("E6AD9C", "A35D48")
        case .mint:     return ("92D1BA", "388568")
        case .sky:      return ("A1C1E6", "4A72A1")
        case .indigo:   return ("ACA6E0", "665EA8")
        case .lavender: return ("D0AAE6", "895BA3")
        case .plum:     return ("E0A6D2", "9E558C")
        case .slate:    return ("C1CCDB", "65758C")
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
