//
//  Store.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import Foundation

final class Store: ObservableObject {
    @Published var islogin = false
    @Published var Conversations: [Conversation] = []
    @Published var friends: [ContactSnapshot] = []
    @Published private(set) var knownUsers: [User] = []
    @Published private(set) var currentUser: UserAccountSnapshot?

    private let authPersistence = ChatAuthPersistenceController.shared
    private let dataPersistence = ChatDataPersistenceController.shared

    init() {
        refreshKnownUsers()
    }

    func login(username: String, password: String) -> Bool {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPassword.isEmpty else { return false }

        guard let account = authPersistence.authenticate(username: trimmedName, password: trimmedPassword) else {
            return false
        }

        beginSession(with: account)
        islogin = true
        return true
    }

    func register(username: String, password: String) -> Bool {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPassword.isEmpty else { return false }

        do {
            let account = try authPersistence.register(username: trimmedName, password: trimmedPassword)
            beginSession(with: account)
            islogin = true
            return true
        } catch {
            return false
        }
    }

    func logout() {
        islogin = false
        Conversations = []
        friends = []
        currentUser = nil
        refreshKnownUsers()
    }

    func addFriend(userId: String) -> Bool {
        guard let currentUser, let target = authPersistence.account(matching: userId) else { return false }
        guard target.id != currentUser.id else { return false }

        let key = Self.directKey(currentUserID: currentUser.id, peerUserID: target.id)
        guard dataPersistence.conversation(directKey: key) == nil else { return false }
        guard !dataPersistence.contactExists(ownerUserID: currentUser.id, peerUserID: target.id) else { return false }

        // Save contact for both users (bidirectional friendship)
        let myContact = ContactSnapshot(
            peerUserID: target.id,
            peerUsername: target.username,
            peerDisplayName: target.displayName,
            peerAvatar: target.avatar
        )
        dataPersistence.saveContact(ownerUserID: currentUser.id, myContact)

        let theirContact = ContactSnapshot(
            peerUserID: currentUser.id,
            peerUsername: currentUser.username,
            peerDisplayName: currentUser.displayName,
            peerAvatar: currentUser.avatar
        )
        dataPersistence.saveContact(ownerUserID: target.id, theirContact)

        refreshFriends()
        refreshKnownUsers()

        let record = dataPersistence.createConversation(
            kind: "direct",
            title: target.displayName,
            avatar: target.avatar,
            directKey: key,
            createdAt: .now
        )
        dataPersistence.addMember(conversationID: Int(record.recordID), userID: currentUser.id, role: "member")
        dataPersistence.addMember(conversationID: Int(record.recordID), userID: target.id, role: "member")

        let conversation = Conversation(
            id: Int(record.recordID),
            avatar: record.avatar,
            title: record.title,
            kind: record.kind,
            lastMessagePreview: record.lastMessagePreview,
            lastMessageAt: record.lastMessageAt,
            groupMembers: [currentUser.makeUser(), target.makeUser()],
            peerUserID: target.id,
            directKey: key,
            createdAt: record.createdAt
        )
        Conversations.append(conversation)
        objectWillChange.send()
        return true
    }

    func createGroup(name: String, members: [User]) -> Bool {
        guard let currentUser else { return false }

        let uniqueMembers = Self.uniqueUsers([currentUser.makeUser()] + members)
        let record = dataPersistence.createConversation(
            kind: "group",
            title: name,
            avatar: "person.2",
            createdAt: .now
        )
        dataPersistence.addMember(conversationID: Int(record.recordID), userID: currentUser.id, role: "owner")
        for member in uniqueMembers where member.id != currentUser.id {
            dataPersistence.addMember(conversationID: Int(record.recordID), userID: member.id, role: "member")
        }

        let conversation = Conversation(
            id: Int(record.recordID),
            avatar: record.avatar,
            title: record.title,
            kind: record.kind,
            lastMessagePreview: record.lastMessagePreview,
            lastMessageAt: record.lastMessageAt,
            groupMembers: uniqueMembers,
            createdAt: record.createdAt
        )
        Conversations.append(conversation)
        objectWillChange.send()
        return true
    }

    func inviteUserToGroup(userId: String, groupId: Int) -> Bool {
        guard let target = authPersistence.account(matching: userId) else { return false }
        guard let index = Conversations.firstIndex(where: { $0.id == groupId && $0.isGroup }) else { return false }

        dataPersistence.addMember(conversationID: groupId, userID: target.id, role: "member")
        if !Conversations[index].groupMembers.contains(where: { $0.id == target.id }) {
            Conversations[index].groupMembers.append(target.makeUser())
        }
        objectWillChange.send()
        return true
    }

    func sendMessage(to conversation: Conversation, content: String) {
        guard let index = Conversations.firstIndex(where: { $0.id == conversation.id }), let currentUser else { return }

        let messageID = dataPersistence.saveMessage(conversationID: conversation.id, senderID: currentUser.id, content: content)
        let now = Date()
        dataPersistence.updateConversationPreview(id: conversation.id, preview: content, at: now)

        let message = ChatMessage(
            id: messageID,
            content: content,
            senderID: currentUser.id,
            senderName: currentUser.displayName,
            isCurrentUser: true
        )
        Conversations[index].messages.append(message)
        Conversations[index].lastMessagePreview = content
        Conversations[index].lastMessageAt = now
        objectWillChange.send()
    }

    func loadKnownUsers() -> [User] {
        let allUsers = authPersistence.loadAccounts().map { $0.makeUser() }
        if let currentUser {
            return allUsers.filter { $0.id != currentUser.id }
        }
        return allUsers
    }

    func openFriend(_ friend: ContactSnapshot) -> Conversation? {
        guard let currentUser else { return nil }
        let key = Self.directKey(currentUserID: currentUser.id, peerUserID: friend.peerUserID)

        if let existing = Conversations.first(where: { $0.directKey == key || $0.peerUserID == friend.peerUserID }) {
            return existing
        }

        guard let record = dataPersistence.conversation(directKey: key) else { return nil }
        let messages = dataPersistence.loadMessages(conversationID: Int(record.recordID))
        let members = dataPersistence.loadMembers(conversationID: Int(record.recordID))
            .compactMap { membership -> User? in
                authPersistence.account(userID: Int(membership.userID))?.makeUser()
            }

        let conversation = Conversation(
            id: Int(record.recordID),
            avatar: friend.peerAvatar,
            title: friend.peerDisplayName,
            kind: record.kind,
            lastMessagePreview: record.lastMessagePreview,
            lastMessageAt: record.lastMessageAt,
            groupMembers: members,
            peerUserID: friend.peerUserID,
            directKey: record.directKey,
            createdAt: record.createdAt
        )
        conversation.messages = messages.map { record in
            let sender = authPersistence.account(userID: Int(record.senderID))
            return ChatMessage(
                id: record.messageID,
                content: record.content,
                senderID: Int(record.senderID),
                senderName: sender?.displayName ?? "用户\(record.senderID)",
                isCurrentUser: Int(record.senderID) == currentUser.id
            )
        }
        Conversations.append(conversation)
        objectWillChange.send()
        return conversation
    }

    private func beginSession(with account: UserAccountSnapshot) {
        currentUser = account
        refreshKnownUsers()
        refreshFriends()

        let records = dataPersistence.loadConversationRecords(for: account.id)
        Conversations = records.map { record in
            let messageRecords = dataPersistence.loadMessages(conversationID: Int(record.recordID))
            let members: [User] = record.kind == "group" ? (
                dataPersistence.loadMembers(conversationID: Int(record.recordID)).compactMap { membership in
                    authPersistence.account(userID: Int(membership.userID))?.makeUser()
                }
            ) : []

            let conversation = Conversation(
                id: Int(record.recordID),
                avatar: record.avatar,
                title: record.title,
                kind: record.kind,
                lastMessagePreview: record.lastMessagePreview,
                lastMessageAt: record.lastMessageAt,
                groupMembers: members,
                directKey: record.directKey,
                createdAt: record.createdAt
            )

            if record.kind != "group", let directKey = record.directKey {
                let pid = Self.peerUserID(from: directKey, currentUserID: account.id)
                if let peer = authPersistence.account(userID: pid) {
                    conversation.title = peer.displayName
                    conversation.avatar = peer.avatar
                    conversation.peerUserID = peer.id
                }
            }

            conversation.messages = messageRecords.map { record in
                let sender = authPersistence.account(userID: Int(record.senderID))
                return ChatMessage(
                    id: record.messageID,
                    content: record.content,
                    senderID: Int(record.senderID),
                    senderName: sender?.displayName ?? "用户\(record.senderID)",
                    isCurrentUser: Int(record.senderID) == account.id
                )
            }
            return conversation
        }

        dataPersistence.onRemoteChange = { [weak self] in
            guard let self, let account = self.currentUser else { return }
            self.refreshFriends()
            self.refreshConversations(for: account)
        }
    }

    private func refreshConversations(for account: UserAccountSnapshot) {
        let records = dataPersistence.loadConversationRecords(for: account.id)
        let oldConversations = Conversations
        Conversations = records.map { record in
            let messageRecords = dataPersistence.loadMessages(conversationID: Int(record.recordID))
            let members: [User] = record.kind == "group" ? (
                dataPersistence.loadMembers(conversationID: Int(record.recordID)).compactMap { membership in
                    authPersistence.account(userID: Int(membership.userID))?.makeUser()
                }
            ) : []

            let old = oldConversations.first(where: { $0.id == Int(record.recordID) })
            let conversation = old ?? Conversation(
                id: Int(record.recordID),
                avatar: record.avatar,
                title: record.title,
                kind: record.kind,
                lastMessagePreview: record.lastMessagePreview,
                lastMessageAt: record.lastMessageAt,
                groupMembers: members,
                directKey: record.directKey,
                createdAt: record.createdAt
            )

            conversation.lastMessagePreview = record.lastMessagePreview
            conversation.lastMessageAt = record.lastMessageAt
            conversation.groupMembers = members
            conversation.messages = messageRecords.map { record in
                let sender = authPersistence.account(userID: Int(record.senderID))
                return ChatMessage(
                    id: record.messageID,
                    content: record.content,
                    senderID: Int(record.senderID),
                    senderName: sender?.displayName ?? "用户\(record.senderID)",
                    isCurrentUser: Int(record.senderID) == account.id
                )
            }

            if record.kind != "group", let directKey = record.directKey {
                let pid = Self.peerUserID(from: directKey, currentUserID: account.id)
                if let peer = authPersistence.account(userID: pid) {
                    conversation.title = peer.displayName
                    conversation.avatar = peer.avatar
                    conversation.peerUserID = peer.id
                }
            }

            return conversation
        }
    }

    func refreshKnownUsers() {
        knownUsers = loadKnownUsers()
    }

    func refreshFriends() {
        guard let currentUser else { return }
        friends = dataPersistence.loadContacts(ownerUserID: currentUser.id)
    }

    private static func directKey(currentUserID: Int, peerUserID: Int) -> String {
        let lower = min(currentUserID, peerUserID)
        let upper = max(currentUserID, peerUserID)
        return "\(lower):\(upper)"
    }

    private static func peerUserID(from directKey: String, currentUserID: Int) -> Int {
        let ids = directKey.split(separator: ":").compactMap { Int($0) }
        if ids.count == 2 {
            return ids[0] == currentUserID ? ids[1] : ids[0]
        }
        return 0
    }

    private static func uniqueUsers(_ users: [User]) -> [User] {
        var seen = Set<Int>()
        var result: [User] = []
        for user in users where !seen.contains(user.id) {
            seen.insert(user.id)
            result.append(user)
        }
        return result
    }
}
