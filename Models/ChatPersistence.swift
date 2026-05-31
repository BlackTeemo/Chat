//
//  ChatPersistence.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import CoreData
import CryptoKit
import Foundation

struct ContactSnapshot: Codable, Identifiable, Hashable {
    let id: Int
    var peerUserID: Int
    var peerUsername: String
    var peerDisplayName: String
    var peerAvatar: String
    var createdAt: Date
    
    init(peerUserID: Int, peerUsername: String, peerDisplayName: String, peerAvatar: String, createdAt: Date = .now) {
        self.id = peerUserID
        self.peerUserID = peerUserID
        self.peerUsername = peerUsername
        self.peerDisplayName = peerDisplayName
        self.peerAvatar = peerAvatar
        self.createdAt = createdAt
    }
    
    func makeUser() -> User {
        User(id: peerUserID, name: peerDisplayName, avatar: peerAvatar)
    }
}

struct UserAccountSnapshot: Codable, Identifiable, Hashable {
    let id: Int
    var username: String
    var displayName: String
    var avatar: String
    var createdAt: Date
    var lastLoginAt: Date?
    
    func makeUser() -> User {
        User(id: id, name: displayName, avatar: avatar)
    }
}

@objc(UserAccountRecord)
final class UserAccountRecord: NSManagedObject {
    @NSManaged var userID: Int64
    @NSManaged var username: String
    @NSManaged var passwordHash: String
    @NSManaged var displayName: String
    @NSManaged var avatar: String
    @NSManaged var createdAt: Date
    @NSManaged var lastLoginAt: Date?
}

@objc(ContactRecord)
final class ContactRecord: NSManagedObject {
    @NSManaged var recordID: Int64
    @NSManaged var ownerUserID: Int64
    @NSManaged var peerUserID: Int64
    @NSManaged var peerUsername: String
    @NSManaged var peerDisplayName: String
    @NSManaged var peerAvatar: String
    @NSManaged var createdAt: Date
}

@objc(ConversationRecord)
final class ConversationRecord: NSManagedObject {
    @NSManaged var recordID: Int64
    @NSManaged var kind: String
    @NSManaged var title: String
    @NSManaged var avatar: String
    @NSManaged var lastMessagePreview: String?
    @NSManaged var lastMessageAt: Date?
    @NSManaged var directKey: String?
    @NSManaged var createdAt: Date
}

@objc(MessageRecord)
final class MessageRecord: NSManagedObject {
    @NSManaged var messageID: Int64
    @NSManaged var conversationID: Int64
    @NSManaged var senderID: Int64
    @NSManaged var content: String
    @NSManaged var messageType: String
    @NSManaged var sentAt: Date
}

@objc(ConversationMemberRecord)
final class ConversationMemberRecord: NSManagedObject {
    @NSManaged var recordID: Int64
    @NSManaged var conversationID: Int64
    @NSManaged var userID: Int64
    @NSManaged var role: String
    @NSManaged var joinedAt: Date
}

final class ChatAuthPersistenceController {
    static let shared = ChatAuthPersistenceController()
    
    private let container: NSPersistentContainer
    
    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ChatAuthPersistence", managedObjectModel: model)
        container.persistentStoreDescriptions = [Self.makeStoreDescription()]
        container.loadPersistentStores { _, error in
            if let error {
                print("Auth CoreData load error: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        seedDefaultAccountIfNeeded()
    }
    
    func loadAccounts() -> [UserAccountSnapshot] {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "userID", ascending: true)]
        
        do {
            let records = try container.viewContext.fetch(request)
            return records.map {
                UserAccountSnapshot(
                    id: Int($0.userID),
                    username: $0.username,
                    displayName: $0.displayName,
                    avatar: $0.avatar,
                    createdAt: $0.createdAt,
                    lastLoginAt: $0.lastLoginAt
                )
            }
        } catch {
            print("Auth CoreData fetch error: \(error.localizedDescription)")
            return []
        }
    }
    
    func account(username: String) -> UserAccountSnapshot? {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            guard let record = try container.viewContext.fetch(request).first else { return nil }
            return snapshot(from: record)
        } catch {
            print("Auth CoreData fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func account(userID: Int) -> UserAccountSnapshot? {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userID == %d", userID)
        
        do {
            guard let record = try container.viewContext.fetch(request).first else { return nil }
            return snapshot(from: record)
        } catch {
            print("Auth CoreData fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func account(matching identifier: String) -> UserAccountSnapshot? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let byUsername = account(username: trimmed) {
            return byUsername
        }
        
        if let userID = Int(trimmed) {
            return account(userID: userID)
        }
        
        return nil
    }
    
    func authenticate(username: String, password: String) -> UserAccountSnapshot? {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            guard let record = try container.viewContext.fetch(request).first else { return nil }
            guard record.passwordHash == Self.hashPassword(password) else { return nil }
            record.lastLoginAt = .now
            try container.viewContext.save()
            return snapshot(from: record)
        } catch {
            print("Auth CoreData auth error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func register(username: String, password: String, displayName: String? = nil, avatar: String = "person.crop.circle") throws -> UserAccountSnapshot {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUsername.isEmpty else {
            throw NSError(domain: "ChatAuthPersistenceController", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户名不能为空"])
        }
        
        if account(username: normalizedUsername) != nil {
            throw NSError(domain: "ChatAuthPersistenceController", code: 2, userInfo: [NSLocalizedDescriptionKey: "用户名已存在"])
        }
        
        let context = container.viewContext
        let record = NSEntityDescription.insertNewObject(forEntityName: "UserAccountRecord", into: context) as! UserAccountRecord
        let newUserID = nextUserID()
        record.userID = Int64(newUserID)
        record.username = normalizedUsername
        record.passwordHash = Self.hashPassword(password)
        let finalDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        record.displayName = (finalDisplayName?.isEmpty == false ? finalDisplayName! : normalizedUsername)
        record.avatar = avatar
        record.createdAt = .now
        record.lastLoginAt = .now
        try context.save()
        return snapshot(from: record)
    }
    
    func updateLastLogin(userID: Int) {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userID == %d", userID)
        
        do {
            guard let record = try container.viewContext.fetch(request).first else { return }
            record.lastLoginAt = .now
            try container.viewContext.save()
        } catch {
            print("Auth CoreData save error: \(error.localizedDescription)")
        }
    }
    
    private func seedDefaultAccountIfNeeded() {
        guard loadAccounts().isEmpty else { return }
        do {
            _ = try register(username: "admin", password: "123456", displayName: "管理员", avatar: "person.crop.circle.fill")
        } catch {
            print("Auth seed error: \(error.localizedDescription)")
        }
    }
    
    private func nextUserID() -> Int {
        let request = NSFetchRequest<UserAccountRecord>(entityName: "UserAccountRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "userID", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let last = try container.viewContext.fetch(request).first?.userID ?? 0
            return Int(last) + 1
        } catch {
            return 1
        }
    }
    
    private func snapshot(from record: UserAccountRecord) -> UserAccountSnapshot {
        UserAccountSnapshot(
            id: Int(record.userID),
            username: record.username,
            displayName: record.displayName,
            avatar: record.avatar,
            createdAt: record.createdAt,
            lastLoginAt: record.lastLoginAt
        )
    }
    
    private static func makeStoreDescription() -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: storeURL())
        description.type = NSSQLiteStoreType
        return description
    }
    
    private static func storeURL() -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Chat", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("ChatAuth.sqlite")
    }
    
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "UserAccountRecord"
        entity.managedObjectClassName = NSStringFromClass(UserAccountRecord.self)

        let userID = NSAttributeDescription()
        userID.name = "userID"
        userID.attributeType = .integer64AttributeType
        userID.isOptional = false
        
        let username = NSAttributeDescription()
        username.name = "username"
        username.attributeType = .stringAttributeType
        username.isOptional = false
        
        let passwordHash = NSAttributeDescription()
        passwordHash.name = "passwordHash"
        passwordHash.attributeType = .stringAttributeType
        passwordHash.isOptional = false
        
        let displayName = NSAttributeDescription()
        displayName.name = "displayName"
        displayName.attributeType = .stringAttributeType
        displayName.isOptional = false
        
        let avatar = NSAttributeDescription()
        avatar.name = "avatar"
        avatar.attributeType = .stringAttributeType
        avatar.isOptional = false
        
        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false
        
        let lastLoginAt = NSAttributeDescription()
        lastLoginAt.name = "lastLoginAt"
        lastLoginAt.attributeType = .dateAttributeType
        lastLoginAt.isOptional = true
        
        entity.properties = [userID, username, passwordHash, displayName, avatar, createdAt, lastLoginAt]
        entity.uniquenessConstraints = [["userID"], ["username"]]
        model.entities = [entity]
        return model
    }
    
    private static func hashPassword(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

final class ChatDataPersistenceController {
    static let shared = ChatDataPersistenceController()

    private let container: NSPersistentContainer
    var onRemoteChange: (() -> Void)?

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ChatData", managedObjectModel: model)
        container.persistentStoreDescriptions = [Self.makeStoreDescription()]
        container.loadPersistentStores { _, error in
            if let error {
                print("ChatData CoreData load error: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        container.viewContext.perform { [weak self] in
            self?.container.viewContext.refreshAllObjects()
            DispatchQueue.main.async {
                self?.onRemoteChange?()
            }
        }
    }

    // MARK: - Conversations

    func loadConversationRecords(for userID: Int) -> [ConversationRecord] {
        let memberRequest = NSFetchRequest<ConversationMemberRecord>(entityName: "ConversationMemberRecord")
        memberRequest.predicate = NSPredicate(format: "userID == %d", userID)

        do {
            let memberRecords = try container.viewContext.fetch(memberRequest)
            let conversationIDs = Set(memberRecords.map { Int($0.conversationID) })
            guard !conversationIDs.isEmpty else { return [] }

            let convRequest = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
            convRequest.predicate = NSPredicate(format: "recordID IN %@", conversationIDs)
            convRequest.sortDescriptors = [
                NSSortDescriptor(key: "lastMessageAt", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: true)
            ]
            return try container.viewContext.fetch(convRequest)
        } catch {
            print("ChatData conversation fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func conversation(recordID: Int) -> ConversationRecord? {
        let request = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "recordID == %d", recordID)

        do {
            return try container.viewContext.fetch(request).first
        } catch {
            print("ChatData conversation fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    func conversation(directKey: String) -> ConversationRecord? {
        let request = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "directKey == %@", directKey)

        do {
            return try container.viewContext.fetch(request).first
        } catch {
            print("ChatData conversation fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    func createConversation(kind: String, title: String, avatar: String, directKey: String? = nil, createdAt: Date = .now) -> ConversationRecord {
        let context = container.viewContext
        let record = NSEntityDescription.insertNewObject(forEntityName: "ConversationRecord", into: context) as! ConversationRecord
        record.recordID = Int64(nextConversationID())
        record.kind = kind
        record.title = title
        record.avatar = avatar
        record.directKey = directKey
        record.createdAt = createdAt

        try? context.save()
        return record
    }

    func updateConversationPreview(id: Int, preview: String, at: Date) {
        guard let record = conversation(recordID: id) else { return }
        record.lastMessagePreview = preview
        record.lastMessageAt = at
        try? container.viewContext.save()
    }

    func nextConversationID() -> Int {
        let request = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "recordID", ascending: false)]
        request.fetchLimit = 1

        do {
            return Int(try container.viewContext.fetch(request).first?.recordID ?? 0) + 1
        } catch {
            return 1
        }
    }

    // MARK: - Messages

    func loadMessages(conversationID: Int) -> [MessageRecord] {
        let request = NSFetchRequest<MessageRecord>(entityName: "MessageRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: true)]
        request.predicate = NSPredicate(format: "conversationID == %d", conversationID)

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("ChatData message fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func saveMessage(conversationID: Int, senderID: Int, content: String, messageType: String = "text") -> Int64 {
        let context = container.viewContext
        let record = NSEntityDescription.insertNewObject(forEntityName: "MessageRecord", into: context) as! MessageRecord
        record.messageID = nextMessageID()
        record.conversationID = Int64(conversationID)
        record.senderID = Int64(senderID)
        record.content = content
        record.messageType = messageType
        record.sentAt = .now

        try? context.save()
        return record.messageID
    }

    func nextMessageID() -> Int64 {
        let request = NSFetchRequest<MessageRecord>(entityName: "MessageRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: false)]
        request.fetchLimit = 1

        do {
            return (try container.viewContext.fetch(request).first?.messageID ?? 0) + 1
        } catch {
            return 1
        }
    }

    // MARK: - Members

    func loadMembers(conversationID: Int) -> [ConversationMemberRecord] {
        let request = NSFetchRequest<ConversationMemberRecord>(entityName: "ConversationMemberRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "joinedAt", ascending: true)]
        request.predicate = NSPredicate(format: "conversationID == %d", conversationID)

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("ChatData member fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func addMember(conversationID: Int, userID: Int, role: String) {
        let request = NSFetchRequest<ConversationMemberRecord>(entityName: "ConversationMemberRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "conversationID == %d AND userID == %d", conversationID, userID)

        do {
            guard try container.viewContext.fetch(request).first == nil else { return }

            let context = container.viewContext
            let record = NSEntityDescription.insertNewObject(forEntityName: "ConversationMemberRecord", into: context) as! ConversationMemberRecord
            record.recordID = nextMemberID()
            record.conversationID = Int64(conversationID)
            record.userID = Int64(userID)
            record.role = role
            record.joinedAt = .now
            try context.save()
        } catch {
            print("ChatData member save error: \(error.localizedDescription)")
        }
    }

    func nextMemberID() -> Int64 {
        let request = NSFetchRequest<ConversationMemberRecord>(entityName: "ConversationMemberRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "recordID", ascending: false)]
        request.fetchLimit = 1

        do {
            return (try container.viewContext.fetch(request).first?.recordID ?? 0) + 1
        } catch {
            return 1
        }
    }

    // MARK: - Contacts

    func loadContacts(ownerUserID: Int) -> [ContactSnapshot] {
        let request = NSFetchRequest<ContactRecord>(entityName: "ContactRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.predicate = NSPredicate(format: "ownerUserID == %d", ownerUserID)

        do {
            return try container.viewContext.fetch(request).map {
                ContactSnapshot(
                    peerUserID: Int($0.peerUserID),
                    peerUsername: $0.peerUsername,
                    peerDisplayName: $0.peerDisplayName,
                    peerAvatar: $0.peerAvatar,
                    createdAt: $0.createdAt
                )
            }
        } catch {
            print("ChatData contact fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func contactExists(ownerUserID: Int, peerUserID: Int) -> Bool {
        let request = NSFetchRequest<ContactRecord>(entityName: "ContactRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "ownerUserID == %d AND peerUserID == %d", ownerUserID, peerUserID)

        do {
            return try container.viewContext.fetch(request).isEmpty == false
        } catch {
            return false
        }
    }

    func saveContact(ownerUserID: Int, _ contact: ContactSnapshot) {
        let context = container.viewContext
        let request = NSFetchRequest<ContactRecord>(entityName: "ContactRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "ownerUserID == %d AND peerUserID == %d", ownerUserID, contact.peerUserID)

        do {
            let record: ContactRecord
            if let existing = try context.fetch(request).first {
                record = existing
            } else {
                record = NSEntityDescription.insertNewObject(forEntityName: "ContactRecord", into: context) as! ContactRecord
                record.recordID = nextContactID()
            }

            record.ownerUserID = Int64(ownerUserID)
            record.peerUserID = Int64(contact.peerUserID)
            record.peerUsername = contact.peerUsername
            record.peerDisplayName = contact.peerDisplayName
            record.peerAvatar = contact.peerAvatar
            record.createdAt = contact.createdAt

            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("ChatData contact save error: \(error.localizedDescription)")
        }
    }

    func nextContactID() -> Int64 {
        let request = NSFetchRequest<ContactRecord>(entityName: "ContactRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "recordID", ascending: false)]
        request.fetchLimit = 1

        do {
            return (try container.viewContext.fetch(request).first?.recordID ?? 0) + 1
        } catch {
            return 1
        }
    }

    // MARK: - Store Setup

    private static func makeStoreDescription() -> NSPersistentStoreDescription {
        let desc = NSPersistentStoreDescription(url: storeURL())
        desc.type = NSSQLiteStoreType
        desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        desc.setOption(true as NSNumber, forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey")
        return desc
    }

    private static func storeURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Chat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ChatData.sqlite")
    }

    // MARK: - Model

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // -- ConversationRecord --
        let conversationEntity = NSEntityDescription()
        conversationEntity.name = "ConversationRecord"
        conversationEntity.managedObjectClassName = NSStringFromClass(ConversationRecord.self)

        let convRecordID = NSAttributeDescription()
        convRecordID.name = "recordID"
        convRecordID.attributeType = .integer64AttributeType
        convRecordID.isOptional = false

        let kind = NSAttributeDescription()
        kind.name = "kind"
        kind.attributeType = .stringAttributeType
        kind.isOptional = false

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false

        let convAvatar = NSAttributeDescription()
        convAvatar.name = "avatar"
        convAvatar.attributeType = .stringAttributeType
        convAvatar.isOptional = false

        let lastMessagePreview = NSAttributeDescription()
        lastMessagePreview.name = "lastMessagePreview"
        lastMessagePreview.attributeType = .stringAttributeType
        lastMessagePreview.isOptional = true

        let lastMessageAt = NSAttributeDescription()
        lastMessageAt.name = "lastMessageAt"
        lastMessageAt.attributeType = .dateAttributeType
        lastMessageAt.isOptional = true

        let directKey = NSAttributeDescription()
        directKey.name = "directKey"
        directKey.attributeType = .stringAttributeType
        directKey.isOptional = true

        let convCreatedAt = NSAttributeDescription()
        convCreatedAt.name = "createdAt"
        convCreatedAt.attributeType = .dateAttributeType
        convCreatedAt.isOptional = false

        conversationEntity.properties = [convRecordID, kind, title, convAvatar, lastMessagePreview, lastMessageAt, directKey, convCreatedAt]
        conversationEntity.uniquenessConstraints = [["recordID"]]

        // -- MessageRecord --
        let messageEntity = NSEntityDescription()
        messageEntity.name = "MessageRecord"
        messageEntity.managedObjectClassName = NSStringFromClass(MessageRecord.self)

        let msgID = NSAttributeDescription()
        msgID.name = "messageID"
        msgID.attributeType = .integer64AttributeType
        msgID.isOptional = false

        let msgConversationID = NSAttributeDescription()
        msgConversationID.name = "conversationID"
        msgConversationID.attributeType = .integer64AttributeType
        msgConversationID.isOptional = false

        let senderID = NSAttributeDescription()
        senderID.name = "senderID"
        senderID.attributeType = .integer64AttributeType
        senderID.isOptional = false

        let content = NSAttributeDescription()
        content.name = "content"
        content.attributeType = .stringAttributeType
        content.isOptional = false

        let messageType = NSAttributeDescription()
        messageType.name = "messageType"
        messageType.attributeType = .stringAttributeType
        messageType.isOptional = false

        let sentAt = NSAttributeDescription()
        sentAt.name = "sentAt"
        sentAt.attributeType = .dateAttributeType
        sentAt.isOptional = false

        messageEntity.properties = [msgID, msgConversationID, senderID, content, messageType, sentAt]
        messageEntity.uniquenessConstraints = [["messageID"]]

        // -- ConversationMemberRecord --
        let memberEntity = NSEntityDescription()
        memberEntity.name = "ConversationMemberRecord"
        memberEntity.managedObjectClassName = NSStringFromClass(ConversationMemberRecord.self)

        let memberRecordID = NSAttributeDescription()
        memberRecordID.name = "recordID"
        memberRecordID.attributeType = .integer64AttributeType
        memberRecordID.isOptional = false

        let memberConversationID = NSAttributeDescription()
        memberConversationID.name = "conversationID"
        memberConversationID.attributeType = .integer64AttributeType
        memberConversationID.isOptional = false

        let memberUserID = NSAttributeDescription()
        memberUserID.name = "userID"
        memberUserID.attributeType = .integer64AttributeType
        memberUserID.isOptional = false

        let role = NSAttributeDescription()
        role.name = "role"
        role.attributeType = .stringAttributeType
        role.isOptional = false

        let joinedAt = NSAttributeDescription()
        joinedAt.name = "joinedAt"
        joinedAt.attributeType = .dateAttributeType
        joinedAt.isOptional = false

        memberEntity.properties = [memberRecordID, memberConversationID, memberUserID, role, joinedAt]
        memberEntity.uniquenessConstraints = [["recordID"], ["conversationID", "userID"]]

        // -- ContactRecord --
        let contactEntity = NSEntityDescription()
        contactEntity.name = "ContactRecord"
        contactEntity.managedObjectClassName = NSStringFromClass(ContactRecord.self)

        let cRecordID = NSAttributeDescription()
        cRecordID.name = "recordID"
        cRecordID.attributeType = .integer64AttributeType
        cRecordID.isOptional = false

        let ownerUserID = NSAttributeDescription()
        ownerUserID.name = "ownerUserID"
        ownerUserID.attributeType = .integer64AttributeType
        ownerUserID.isOptional = false

        let cPeerUserID = NSAttributeDescription()
        cPeerUserID.name = "peerUserID"
        cPeerUserID.attributeType = .integer64AttributeType
        cPeerUserID.isOptional = false

        let cPeerUsername = NSAttributeDescription()
        cPeerUsername.name = "peerUsername"
        cPeerUsername.attributeType = .stringAttributeType
        cPeerUsername.isOptional = false

        let cPeerDisplayName = NSAttributeDescription()
        cPeerDisplayName.name = "peerDisplayName"
        cPeerDisplayName.attributeType = .stringAttributeType
        cPeerDisplayName.isOptional = false

        let cPeerAvatar = NSAttributeDescription()
        cPeerAvatar.name = "peerAvatar"
        cPeerAvatar.attributeType = .stringAttributeType
        cPeerAvatar.isOptional = false

        let cCreatedAt = NSAttributeDescription()
        cCreatedAt.name = "createdAt"
        cCreatedAt.attributeType = .dateAttributeType
        cCreatedAt.isOptional = false

        contactEntity.properties = [cRecordID, ownerUserID, cPeerUserID, cPeerUsername, cPeerDisplayName, cPeerAvatar, cCreatedAt]
        contactEntity.uniquenessConstraints = [["ownerUserID", "peerUserID"]]

        model.entities = [conversationEntity, messageEntity, memberEntity, contactEntity]
        return model
    }
}
