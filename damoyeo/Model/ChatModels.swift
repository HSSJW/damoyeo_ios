import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - ChatRoom Model
struct ChatRoom {
    let id: String
    let users: [String]
    let lastMessage: String
    let timestamp: Date?
    let pinned: Bool
    
    init(id: String, users: [String], lastMessage: String, timestamp: Date?, pinned: Bool) {
        self.id = id
        self.users = users
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.pinned = pinned
    }
    
    // Firestore 문서에서 ChatRoom 객체로 변환
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        self.id = document.documentID
        self.users = data["users"] as? [String] ?? []
        self.lastMessage = data["lastMessage"] as? String ?? ""
        self.pinned = data["pinned"] as? Bool ?? false
        
        if let timestamp = data["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.users = data["users"] as? [String] ?? []
        self.lastMessage = data["lastMessage"] as? String ?? ""
        self.pinned = data["pinned"] as? Bool ?? false
        
        if let timestamp = data["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }
    
    // ChatRoom 객체를 Firestore 문서로 변환
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "users": users,
            "lastMessage": lastMessage,
            "pinned": pinned
        ]
        
        if let timestamp = timestamp {
            dict["timestamp"] = Timestamp(date: timestamp)
        }
        
        return dict
    }
    
    func getOtherUserId() -> String {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return "" }
        return users.first { $0 != currentUserId } ?? ""
    }
}

// MARK: - ChatMessage Model
struct ChatMessage {
    let messageId: String
    let senderId: String
    let senderName: String
    let message: String
    let timestamp: Date?
    let isRead: Bool
    
    init(messageId: String, senderId: String, senderName: String, message: String, timestamp: Date? = nil, isRead: Bool = false) {
        self.messageId = messageId
        self.senderId = senderId
        self.senderName = senderName
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    // Firestore 문서에서 ChatMessage 객체로 변환
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        self.messageId = document.documentID
        self.senderId = data["senderId"] as? String ?? ""
        self.senderName = data["senderName"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.isRead = data["isRead"] as? Bool ?? false
        
        if let timestamp = data["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }
    
    // ChatMessage 객체를 Firestore 문서로 변환
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "senderId": senderId,
            "senderName": senderName,
            "message": message,
            "isRead": isRead
        ]
        
        if let timestamp = timestamp {
            dict["timestamp"] = Timestamp(date: timestamp)
        } else {
            dict["timestamp"] = FieldValue.serverTimestamp()
        }
        
        return dict
    }
}

// MARK: - User Model
struct User {
    let id: String
    let userName: String
    let userNickname: String
    let userEmail: String
    let userPhoneNum: String
    let profileImage: String?
    let userCreatedAt: Date?
    let userPostCount: Int
    
    init(id: String, userName: String, userNickname: String, userEmail: String, userPhoneNum: String, profileImage: String? = nil, userCreatedAt: Date? = nil, userPostCount: Int = 0) {
        self.id = id
        self.userName = userName
        self.userNickname = userNickname
        self.userEmail = userEmail
        self.userPhoneNum = userPhoneNum
        self.profileImage = profileImage
        self.userCreatedAt = userCreatedAt
        self.userPostCount = userPostCount
    }
    
    // Firestore 문서에서 User 객체로 변환
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userName = data["user_name"] as? String ?? ""
        self.userNickname = data["user_nickname"] as? String ?? ""
        self.userEmail = data["user_email"] as? String ?? ""
        self.userPhoneNum = data["user_phoneNum"] as? String ?? ""
        self.profileImage = data["profile_image"] as? String
        self.userPostCount = data["user_PostCount"] as? Int ?? 0
        
        if let timestamp = data["user_createdAt"] as? Timestamp {
            self.userCreatedAt = timestamp.dateValue()
        } else {
            self.userCreatedAt = nil
        }
    }
}
