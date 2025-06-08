import Foundation

struct Post {
    let id: String
    let title: String
    let content: String
    let tag: String // 지역
    let recruit: Int // 모집인원
    let createdAt: Date
    let imageUrl: String
    let imageUrls: [String]
    let address: String
    let detailAddress: String
    let category: String
    let cost: Int
    let meetingTime: Date
    let authorId: String
    
    // 초기화
    init(id: String = UUID().uuidString,
         title: String,
         content: String,
         tag: String,
         recruit: Int,
         createdAt: Date = Date(),
         imageUrl: String = "",
         imageUrls: [String] = [],
         address: String,
         detailAddress: String,
         category: String,
         cost: Int,
         meetingTime: Date,
         authorId: String) {
        
        self.id = id
        self.title = title
        self.content = content
        self.tag = tag
        self.recruit = recruit
        self.createdAt = createdAt
        self.imageUrl = imageUrl
        self.imageUrls = imageUrls
        self.address = address
        self.detailAddress = detailAddress
        self.category = category
        self.cost = cost
        self.meetingTime = meetingTime
        self.authorId = authorId
    }
}
