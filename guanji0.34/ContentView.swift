//
//  ContentView.swift
//  guanji0.34
//
//  Created by hansne on 2025/12/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    var body: some View {
        NavigationStack { TimelineScreen() }
            .environmentObject(appState)
    }
}

#Preview { ContentView() }
