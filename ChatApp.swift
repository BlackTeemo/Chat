//
//  ChatApp.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

@main
struct ChatApp: App {
    
    @StateObject var store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
