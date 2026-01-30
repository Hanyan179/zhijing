//
//  guanji0_34App.swift
//  guanji0.34
//
//  Created by hansne on 2025/12/1.
//
//  应用入口点
//  使用 RootView 作为根视图，根据认证状态显示不同界面
//  - Requirements: 11.1, 11.2
//

import SwiftUI

@main
struct guanji0_34App: App {
    var body: some Scene {
        WindowGroup {
            // 使用 RootView 作为根视图
            // 根据认证状态显示登录界面或主应用界面
            // - Requirements: 11.1, 11.2
            RootView()
        }
    }
}
