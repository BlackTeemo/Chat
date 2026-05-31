//
//  SidebarView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store : Store
    @Binding var selectedConversation: Conversation?
    @State private var showCreateGroupModal = false
    @State private var showAddFriendModal = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("会话")
                        .font(.title2.bold())
                    Text("选择一个对话开始聊天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            List {
                Section("好友") {
                    if store.friends.isEmpty {
                        Text("暂无好友")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.friends) { friend in
                            Button {
                                selectedConversation = store.openFriend(friend)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: friend.peerAvatar)
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(width: 34, height: 34)
                                        .background(Color.accentColor.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(friend.peerDisplayName)
                                            .font(.headline)
                                        Text(friend.peerUsername)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("会话") {
                    ForEach(store.Conversations) { conversation in
                        Button {
                            selectedConversation = conversation
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: conversation.avatar)
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(width: 34, height: 34)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(conversation.title)
                                            .font(.headline)
                                        
                                        if conversation.isGroup {
                                            Text("群聊")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text(conversation.lastMessagePreview ?? "暂无消息")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 6)
                            .background(selectedConversation?.id == conversation.id ? Color.accentColor.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: { showAddFriendModal = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    
                    Button(action: { showCreateGroupModal = true }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateGroupModal) {
            CreateGroupView(isPresented: $showCreateGroupModal)
                .environmentObject(store)
        }
        .sheet(isPresented: $showAddFriendModal) {
            AddFriendView(isPresented: $showAddFriendModal)
                .environmentObject(store)
        }
    }
}

//#Preview {
//    SidebarView()
//}
