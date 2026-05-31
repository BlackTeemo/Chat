//
//  Conversation.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import Foundation

struct ChatMessage: Identifiable {
    let id: Int64
    let content: String
    let senderID: Int
    let senderName: String
    let isCurrentUser: Bool
}

final class Conversation: Identifiable, ObservableObject {
    let id: Int
    @Published var avatar: String
    @Published var title: String
    @Published var kind: String
    @Published var lastMessagePreview: String?
    @Published var lastMessageAt: Date?
    @Published var groupMembers: [User]
    var peerUserID: Int?
    var directKey: String?
    let createdAt: Date

    @Published var messages = [ChatMessage]()
    
    var isGroup: Bool { kind == "group" }
    
    init(id: Int, avatar: String, title: String, kind: String, lastMessagePreview: String? = nil, lastMessageAt: Date? = nil, groupMembers: [User] = [], peerUserID: Int? = nil, directKey: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.avatar = avatar
        self.title = title
        self.kind = kind
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.groupMembers = groupMembers
        self.peerUserID = peerUserID
        self.directKey = directKey
        self.createdAt = createdAt
    }
}
