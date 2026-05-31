//
//  ChatMessageView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct ChatMessageView: View {

    @ObservedObject var conversation: Conversation

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if conversation.messages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)
                        Text("还没有消息，发一条试试")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(conversation.messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 3) {
                if !message.isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isCurrentUser ? Color.accentColor : Color.gray.opacity(0.12))
                    .foregroundStyle(message.isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !message.isCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

//#Preview {
//    ChatMessageView()
//}
