//
//  User.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import Foundation

class User: Identifiable, ObservableObject {
    var id: Int
    var name: String
    var avatar: String
    
    init(id: Int, name: String, avatar: String) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}
