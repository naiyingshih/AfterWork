//
//  UserInfoManager.swift
//  AfterWork
//
//  Created by NY.
//

import Foundation

class UserInfoManager {
    static let shared = UserInfoManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - 目標-卡片展開狀態
    
    func setGoalExpanded(_ isExpanded: Bool, for id: String) {
        defaults.set(isExpanded, forKey: "expanded-\(id)")
    }
    
    func isGoalExpanded(for id: String, default defaultVal: Bool) -> Bool {
        let key = "expanded-\(id)"
        if defaults.object(forKey: key) == nil {
            return defaultVal
        }
        return defaults.bool(forKey: key)
    }
}
