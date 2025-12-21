import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userPhotoURL: URL?
    let text: String
    let createdAt: Date
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "userName": userName,
            "userPhotoURL": userPhotoURL?.absoluteString ?? "",
            "text": text,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    init(id: String, userId: String, userName: String, userPhotoURL: URL?, text: String, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.text = text
        self.createdAt = createdAt
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let userName = dictionary["userName"] as? String,
              let text = dictionary["text"] as? String else { return nil }
        
        self.id = id
        self.userId = userId
        self.userName = userName
        if let photoStr = dictionary["userPhotoURL"] as? String, !photoStr.isEmpty {
            self.userPhotoURL = URL(string: photoStr)
        } else {
            self.userPhotoURL = nil
        }
        self.text = text
        self.createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
