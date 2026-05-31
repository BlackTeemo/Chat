//
//  ConversationView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var store : Store
    let conversation : Conversation
    @State private var showInviteUserModal = false
    var body: some View {
        VStack(spacing: 0){
            HeaderView(conversation: conversation) {
                showInviteUserModal = true
            }
            Divider()
            ChatMessageView(conversation:conversation)
            Divider()
            MessageInputView(conversation:conversation)
            
        }
        .navigationTitle(conversation.title)
        .sheet(isPresented: $showInviteUserModal) {
            InviteUserView(conversation: conversation, isPresented: $showInviteUserModal)
                .environmentObject(store)
        }
       
    }
}

//#Preview {
//    ConversationView()
//}
