//
//  HeaderView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct HeaderView: View {
    
    let conversation : Conversation
    var onInvite: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: conversation.avatar)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(conversation.title)
                        .font(.headline)
                    
                    Text(conversation.isGroup ? "群聊" : "私聊")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Text(conversation.isGroup ? "\(conversation.groupMembers.count) 位成员" : "正在聊天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if conversation.isGroup, let onInvite {
                Button {
                    onInvite()
                } label: {
                    Label("邀请", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }
}

//#Preview {
//    HeaderView()
//}
