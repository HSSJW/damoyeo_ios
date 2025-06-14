import Foundation

struct Post {
    let id: String              // 게시물 ID (Firestore document ID)
    let title: String
    let content: String
    let tag: String             // 지역 정보
    let recruit: Int            // 모집 인원
    let createdAt: Date
    let imageUrl: String        // 기본 이미지 URL
    let imageUrls: [String]     // 추가 이미지 URLs
    let address: String         // 주소
    let detailAddress: String   // 상세 주소
    let category: String        // 카테고리
    let cost: Int              // 참여 비용
    let meetingTime: Date      // 모임 시간
    let authorId: String       // 작성자 ID
    
    init(id: String, title: String, content: String, tag: String, recruit: Int,
         createdAt: Date, imageUrl: String, imageUrls: [String], address: String,
         detailAddress: String, category: String, cost: Int, meetingTime: Date, authorId: String) {
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
