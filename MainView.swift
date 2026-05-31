//
//  MainView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct MainView: View {
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationSplitView{
            SidebarView(selectedConversation: $selectedConversation)
        } detail: {
            if let selected = selectedConversation {
                ConversationView(conversation: selected)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    
                    Text("欢迎")
                        .font(.title2.bold())
                    
                    Text("从左侧选择一个会话，或者新建群聊、添加好友开始演示。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            }
        }
    }
}

//#Preview {
//    MainView()
//}
