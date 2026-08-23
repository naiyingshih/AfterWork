//
//  AppDelegate.swift
//  AfterWork
//
//  Created by NY on 2026/3/21.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    configureAppearance()

    return true
  }

  /// NavigationBar 與 TabBar 是 UIKit 畫的，SwiftUI 的 modifier 蓋不到，
  /// 所以在這裡統一換成 Assets 裡的色票，否則內容區是米色、導覽列卻還是系統灰。
  private func configureAppearance() {
    let background = UIColor(resource: .background)
    let card = UIColor(resource: .card)
    let label = UIColor(resource: .label)
    let main = UIColor(resource: .main)
    let labelSecondary = label.withAlphaComponent(0.6)

    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithOpaqueBackground()
    navAppearance.backgroundColor = background
    navAppearance.shadowColor = .clear
    navAppearance.titleTextAttributes = [.foregroundColor: label]
    navAppearance.largeTitleTextAttributes = [.foregroundColor: label]

    UINavigationBar.appearance().standardAppearance = navAppearance
    UINavigationBar.appearance().compactAppearance = navAppearance
    // 刻意不設 scrollEdgeAppearance：iOS 26 上透過 appearance proxy 指定不透明的
    // scrollEdgeAppearance 會讓 SwiftUI 的大標題完全不繪製（版面空間還在但沒有字）。
    // 頁面背景本來就是 background 色，捲到頂時沿用系統的透明導覽列，視覺結果一樣。
    UINavigationBar.appearance().tintColor = main

    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithOpaqueBackground()
    tabAppearance.backgroundColor = card
    tabAppearance.shadowColor = label.withAlphaComponent(0.12)

    for itemAppearance in [tabAppearance.stackedLayoutAppearance,
                           tabAppearance.inlineLayoutAppearance,
                           tabAppearance.compactInlineLayoutAppearance] {
      itemAppearance.selected.iconColor = main
      itemAppearance.selected.titleTextAttributes = [.foregroundColor: main]
      itemAppearance.normal.iconColor = labelSecondary
      itemAppearance.normal.titleTextAttributes = [.foregroundColor: labelSecondary]
    }

    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
  }
}
