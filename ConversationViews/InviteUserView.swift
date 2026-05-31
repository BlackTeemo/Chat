//
//  InviteUserView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct InviteUserView: View {
    @EnvironmentObject var store: Store
    let conversation: Conversation
    @Binding var isPresented: Bool
    @State private var selectedUserId = ""
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("邀请用户进群")
                    .font(.title2.bold())
                Spacer()
                Button("取消") {
                    isPresented = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Form {
                Section("选择要邀请的用户") {
                    Picker("选择用户", selection: $selectedUserId) {
                        Text("请选择") .tag("")
                        ForEach(store.friends, id: \.peerUserID) { friend in
                            Text(friend.peerDisplayName).tag(String(friend.peerUserID))
                        }
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Button("邀请") {
                if !selectedUserId.isEmpty {
                    if store.inviteUserToGroup(userId: selectedUserId, groupId: conversation.id) {
                        isPresented = false
                    } else {
                        statusMessage = "邀请失败"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedUserId.isEmpty)
            .padding(20)
        }
        .frame(width: 380, height: 260)
        .onAppear { store.refreshFriends() }
    }
}

//#Preview {
//    InviteUserView(conversation: Conversation(id: 1, avatar: "person.2", title: "群聊"), isPresented: .constant(true))
//}
