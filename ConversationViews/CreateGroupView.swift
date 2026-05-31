//
//  CreateGroupView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var store: Store
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var selectedMembers: [User] = []
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("创建群聊")
                    .font(.title2.bold())
                Spacer()
                Button("取消") {
                    isPresented = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("群聊名称")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("输入群聊名称", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("选择成员")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    List(store.knownUsers, id: \.id) { member in
                        HStack {
                            Image(systemName: member.avatar)
                            Text(member.name)
                            Spacer()
                            if selectedMembers.contains(where: { $0.id == member.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .onTapGesture {
                            if let index = selectedMembers.firstIndex(where: { $0.id == member.id }) {
                                selectedMembers.remove(at: index)
                            } else {
                                selectedMembers.append(member)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(minHeight: 160)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Button("创建") {
                if !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if store.createGroup(name: groupName, members: selectedMembers) {
                        isPresented = false
                    } else {
                        statusMessage = "创建失败"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(groupName.isEmpty)
            .padding(20)
        }
        .frame(width: 400, height: 420)
    }
}

//#Preview {
//    CreateGroupView(isPresented: .constant(true))
//}
