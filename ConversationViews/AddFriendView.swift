//
//  AddFriendView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct AddFriendView: View {
    @EnvironmentObject var store: Store
    @Binding var isPresented: Bool
    @State private var friendId = ""
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("添加好友")
                    .font(.title2.bold())
                Spacer()
                Button("取消") {
                    isPresented = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text("好友用户名或ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("输入要添加的用户名", text: $friendId)
                    .textFieldStyle(.roundedBorder)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Button("添加") {
                if !friendId.isEmpty {
                    if store.addFriend(userId: friendId) {
                        isPresented = false
                    } else {
                        statusMessage = "未找到用户或已添加"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(friendId.isEmpty)
            .padding(20)
        }
        .frame(width: 380, height: 240)
    }
}

//#Preview {
//    AddFriendView(isPresented: .constant(true))
//}
