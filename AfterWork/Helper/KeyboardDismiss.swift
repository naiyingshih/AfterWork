//
//  KeyboardDismiss.swift
//  AfterWork
//
//  Created by NY on 2026/8/29.
//

import SwiftUI

extension View {
    /// 點畫面空白處收鍵盤。掛在有輸入框的畫面最外層。
    /// 注意：`Form`／`List` 會自己吃掉空白處的點擊，掛上去不會生效。
    func hideKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}
