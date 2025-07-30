import Foundation

struct CreditProduct {
    let productId: String
    let credits: Int
    let price: String
    let displayName: String
    let description: String
    
    static let allProducts = [
        CreditProduct(
            productId: "credits_100",
            credits: 100,
            price: "₩2,500",
            displayName: "100 크레딧",
            description: "기본 크레딧 패키지"
        ),
        CreditProduct(
            productId: "credits_500",
            credits: 550,  // 보너스 50 포함
            price: "₩6,500",
            displayName: "500 크레딧",
            description: "인기 크레딧 패키지 (보너스 50 크레딧)"
        ),
        CreditProduct(
            productId: "credits_1000",
            credits: 1200,  // 보너스 200 포함
            price: "₩12,500",
            displayName: "1000 크레딧",
            description: "최고 가치 패키지 (보너스 200 크레딧)"
        )
    ]
}
