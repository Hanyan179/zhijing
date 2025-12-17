//
//  guanji0_34App.swift
//  guanji0.34
//
//  Created by hansne on 2025/12/1.
//

import SwiftUI

@main
struct guanji0_34App: App {
    
    init() {
        // Migrate old MindState data to new DailyTracker format
        DailyTrackerRepository.shared.migrateFromMindState()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
