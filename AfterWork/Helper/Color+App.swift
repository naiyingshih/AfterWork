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

    /// 大面積的主色填色（FAB、日曆選取日、Toggle、滑動按鈕）。
    /// `main` 在深色模式是文字用的淺綠（#B9C99D），拿來當底色時白字看不清楚，
    /// 所以填色在深色模式維持設計稿的深綠 #588157。
    static var mainFill: Color { Color(light: Color.main, dark: Color(hex: "588157")) }

    /// 疊在 `mainFill` 之上的前景色。兩個模式的填色都是深綠，前景一律用近白色。
    static var onMain: Color { Color(hex: "F9F9F9") }

    /// 輸入框的底色。淺色模式跟分隔線同色（#E7E7E7）；深色模式依設計稿用卡片色。
    static var fieldBackground: Color { Color(light: Color.hairline, dark: Color.card) }

    /// 目標描述泡泡。深色模式依設計稿：底色 #5F6E64（labelSecondary 的淺色值），文字近白色。
    static var descriptionBubble: Color { Color(light: Color.onFill.opacity(0.15), dark: Color(hex: "5F6E64")) }
    static var onDescriptionBubble: Color { Color(light: Color.labelSecondary, dark: Color(hex: "F9F9F9")) }
}

// MARK: - 習慣配色
/// 內建三種類型用色票（Assets.xcassets/Colors），「其他」用下面這組固定色。
extension HabitStyle {

    /// 大面積填色用的粉彩色。深色模式用同色相、飽和度較高且稍暗的版本，在深色卡片上才分得出顏色。
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
/// - 淺色 `fillColor` 對 `Color.onFill`(#344E41)：4.8~7.6:1
/// - 深色 `fillColor` 對 `Color.onFill`：4.5~7.1:1（調高飽和度時以 4.5:1 為下限）
/// - 淺色 `accentColor` 對 `Color.card`(#FFFFFF)：2.9~5.0:1。yellow 只有 2.9:1，是設計稿的值
/// - 深色 `accentColor` 對深色 `Color.card`(#313B35)：5.8~9.1:1
///
/// 深色模式的 accent 直接用深色填色本身，跟 `choresAccent` / `learningAccent` 的作法一致。
extension HabitTagColor {

    var fillColor: Color {
        Color(light: Color(hex: hexes.fill), dark: Color(hex: hexes.fillDark))
    }

    var accentColor: Color {
        Color(light: Color(hex: hexes.accentLight), dark: Color(hex: hexes.fillDark))
    }

    private var hexes: (fill: String, fillDark: String, accentLight: String) {
        switch self {
        case .coral:  return ("F3C3B5", "EBA5A0", "A68379")
        case .mint:   return ("9DDFC6", "75E3B9", "388568")
        case .sky:    return ("A3BDF5", "9CB8F4", "4A72A1")
        case .indigo: return ("CDBFEF", "C0ACF3", "8D80AC")
        case .yellow: return ("F5EDAE", "F1E68E", "A39960")
        case .slate:  return ("D6D6D7", "C4C4C5", "8A8A8C")
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
