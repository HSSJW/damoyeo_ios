import Foundation
import StoreKit

class MockPaymentManager: NSObject, ObservableObject {
    static let shared = MockPaymentManager()
    
    @Published var isLoading = false
    @Published var purchaseResult: PurchaseResult?
    
    enum PurchaseResult {
        case success(credits: Int, transactionId: String)
        case failure(error: String)
        case cancelled
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Mock 크레딧 구매 시뮬레이션
    func purchaseCredits(productId: String, completion: @escaping (PurchaseResult) -> Void) {
        print("🛒 Mock 크레딧 구매 시작: \(productId)")
        
        guard let product = CreditProduct.allProducts.first(where: { $0.productId == productId }) else {
            completion(.failure(error: "상품을 찾을 수 없습니다."))
            return
        }
        
        isLoading = true
        
        // 실제 결제를 시뮬레이션하기 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            
            // 90% 확률로 성공 (테스트용)
            let randomValue = Int.random(in: 1...10)
            
            if randomValue <= 9 {
                let mockTransactionId = "mock_credit_\(Date().timeIntervalSince1970)"
                let result = PurchaseResult.success(credits: product.credits, transactionId: mockTransactionId)
                self.purchaseResult = result
                completion(result)
                
                print("✅ Mock 크레딧 구매 성공: \(product.credits) 크레딧, ID: \(mockTransactionId)")
            } else {
                let result = PurchaseResult.failure(error: "결제가 실패했습니다. 다시 시도해주세요.")
                self.purchaseResult = result
                completion(result)
                
                print("❌ Mock 크레딧 구매 실패")
            }
        }
    }
    
    // MARK: - 서버에 결제 결과 전송
    func sendPurchaseToServer(transactionId: String, productId: String, credits: Int, completion: @escaping (Bool) -> Void) {
        print("📤 서버에 크레딧 결제 정보 전송: \(transactionId)")
        
        let mockReceiptData = createMockReceiptData(transactionId: transactionId, productId: productId)
        
        let paymentData: [String: Any] = [
            "receiptData": mockReceiptData,
            "transactionId": transactionId,
            "productId": productId,
            "creditAmount": credits,
            "platform": "iOS",
            "amount": getProductPrice(for: productId)
        ]
        
        callServerAPI(data: paymentData, completion: completion)
    }
    
    // MARK: - Private Methods
    private func createMockReceiptData(transactionId: String, productId: String) -> String {
        let mockReceipt: [String: Any] = [  // 타입 명시적 지정
            "transaction_id": transactionId,
            "product_id": productId,
            "purchase_date": Date().timeIntervalSince1970,
            "environment": "sandbox"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: mockReceipt),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return Data(jsonString.utf8).base64EncodedString()
        }
        
        return "mock_receipt_data"
    }
    
    private func getProductPrice(for productId: String) -> Int {
        switch productId {
        case "credits_100": return 2500
        case "credits_500": return 6500
        case "credits_1000": return 12500
        default: return 0
        }
    }
    
    private func callServerAPI(data: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:8080/api/users/credits/payment") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // JWT 토큰 추가 (Firebase에서 가져오기)
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
            print("📤 서버 요청: \(url)")
            print("📤 Request data: \(data)")
        } catch {
            print("❌ JSON 직렬화 실패: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 서버 API 호출 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 서버 응답 코드: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let data = data,
                           let responseString = String(data: data, encoding: .utf8) {
                            print("📥 서버 응답: \(responseString)")
                        }
                        print("✅ 서버 API 호출 성공")
                        completion(true)
                    } else {
                        print("❌ 서버 응답 에러: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    print("❌ Invalid HTTP response")
                    completion(false)
                }
            }
        }.resume()
    }
    
    private func getCurrentUserToken() -> String? {
        // Firebase Auth에서 현재 사용자 토큰 가져오기
        // 실제 구현 시 Firebase Auth의 getIDToken 사용
        return nil
    }
}
