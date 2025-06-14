import Foundation

class FirebaseAIManager {
    static let shared = FirebaseAIManager()
    private init() {}
    
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["GEMINI_API_KEY"] as? String else {
            print(" Gemini API Key not found in GoogleService-Info.plist")
            return "YOUR_API_KEY_HERE"
        }
        print(" API Key 읽기 성공: \(apiKey)") // 디버깅용 추가
        return apiKey
    }
    
    // MARK: - 메인 게시물 생성 메서드
    func generatePost(from naturalLanguage: String, completion: @escaping (Result<GeneratedPostData, APIError>) -> Void) {
        
        // URL 생성
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            completion(Result<GeneratedPostData, APIError>.failure(APIError.invalidURL))
            return
        }
        
        // URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 프롬프트 생성
        let prompt = createPrompt(from: naturalLanguage)
        let requestBody = createRequestBody(prompt: prompt)
        
        // Request Body 설정
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(Result<GeneratedPostData, APIError>.failure(APIError.jsonParseError))
            return
        }
        
        // API 호출
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            // 네트워크 에러 체크
            if let error = error {
                print(" Network Error: \(error)")
                completion(Result<GeneratedPostData, APIError>.failure(APIError.invalidResponse))
                return
            }
            
            // HTTP 응답 체크
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(Result<GeneratedPostData, APIError>.failure(APIError.invalidResponse))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print(" HTTP Error: \(httpResponse.statusCode)")
                completion(Result<GeneratedPostData, APIError>.failure(APIError.httpError(httpResponse.statusCode)))
                return
            }
            
            // 데이터 체크
            guard let data = data else {
                completion(Result<GeneratedPostData, APIError>.failure(APIError.noData))
                return
            }
            
            // 응답 파싱
            self?.parseResponse(data: data, completion: completion)
            
        }.resume()
    }
    
    // MARK: - 프롬프트 생성
    private func createPrompt(from naturalLanguage: String) -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: currentDate)
        
        return """
        당신은 모임 게시물 생성 전문가입니다. 다음 자연어 설명을 바탕으로 한국의 모임 게시물 정보를 JSON 형태로 생성해주세요.
        
        오늘 날짜: \(today)
        사용자 입력: "\(naturalLanguage)"
        
        다음 규칙을 따라주세요:
        1. 한국의 실제 지역과 장소를 기준으로 생성
        2. 현실적인 금액과 인원수 제안
        3. meetingDate는 반드시 \(today) 이후 날짜로 설정
        4. 친근하고 매력적인 문체 사용
        5. 안전하고 건전한 모임 내용만 생성
        
        정확히 다음 JSON 형식으로만 응답해주세요:
        {
            "title": "게시물 제목 (30자 이내, 매력적으로)",
            "content": "게시물 내용 (100-300자, 친근하고 자세하게)",
            "category": "친목|스포츠|스터디|여행|알바|게임|봉사|헬스|음악|기타 중 하나",
            "region": "서울특별시|부산광역시|대구광역시|인천광역시|광주광역시|대전광역시|울산광역시|세종특별자치시|경기도|강원도|충청북도|충청남도|전라북도|전라남도|경상북도|경상남도|제주특별자치도 중 하나",
            "address": "구체적인 주소 (시/군/구/동 까지)",
            "detailAddress": "상세 주소 (건물명, 랜드마크 등)",
            "recruit": 2-20 사이의 숫자,
            "cost": 0-100000 사이의 숫자 (원 단위),
            "meetingDate": "\(today) 이후 1개월 이내 날짜 (YYYY-MM-DD 형식)",
            "meetingTime": "HH:mm" (09:00-22:00 사이)
        }
        """
    }
    
    // MARK: - Request Body 생성
    private func createRequestBody(prompt: String) -> [String: Any] {
        return [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048,
                "stopSequences": []
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ]
            ]
        ]
    }
    
    // MARK: - 응답 파싱
    private func parseResponse(data: Data, completion: @escaping (Result<GeneratedPostData, APIError>) -> Void) {
        
        do {
            // JSON 파싱
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(Result<GeneratedPostData, APIError>.failure(APIError.invalidJSON))
                return
            }
            
            print(" API Response: \(json)")
            
            // Gemini API 응답 구조 파싱
            guard let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                
                print("❌ Invalid API response structure")
                completion(Result<GeneratedPostData, APIError>.failure(APIError.invalidResponse))
                return
            }
            
            print(" Generated Text: \(text)")
            
            // JSON 텍스트에서 실제 JSON 추출
            let cleanedText = extractJSONFromText(text)
            
            guard let jsonData = cleanedText.data(using: .utf8),
                  let postJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                
                print("❌ Failed to parse JSON from text: \(cleanedText)")
                completion(Result<GeneratedPostData, APIError>.failure(APIError.jsonParseError))
                return
            }
            
            // GeneratedPostData로 변환
            do {
                let postData = try parseGeneratedPost(from: postJson)
                completion(Result<GeneratedPostData, APIError>.success(postData))
            } catch let parseError as APIError {
                completion(Result<GeneratedPostData, APIError>.failure(parseError))
            } catch {
                completion(Result<GeneratedPostData, APIError>.failure(APIError.jsonParseError))
            }
            
        } catch {
            print("❌ Parsing Error: \(error)")
            completion(Result<GeneratedPostData, APIError>.failure(APIError.jsonParseError))
        }
    }
    
    // MARK: - JSON 텍스트 추출
    private func extractJSONFromText(_ text: String) -> String {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ```json 과 ``` 제거
        var jsonText = cleanedText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // { 로 시작하고 } 로 끝나는 부분 찾기
        if let startIndex = jsonText.firstIndex(of: "{"),
           let endIndex = jsonText.lastIndex(of: "}") {
            jsonText = String(jsonText[startIndex...endIndex])
        }
        
        return jsonText
    }
    
    // MARK: - GeneratedPostData 파싱
    private func parseGeneratedPost(from json: [String: Any]) throws -> GeneratedPostData {
        
        // 필수 필드 체크
        guard let title = json["title"] as? String,
              let content = json["content"] as? String,
              let category = json["category"] as? String,
              let region = json["region"] as? String,
              let address = json["address"] as? String,
              let detailAddress = json["detailAddress"] as? String,
              let recruit = json["recruit"] as? Int,
              let cost = json["cost"] as? Int,
              let meetingDate = json["meetingDate"] as? String,
              let meetingTime = json["meetingTime"] as? String else {
            
            print(" Missing required fields in JSON: \(json)")
            throw APIError.missingRequiredFields
        }
        
        // 날짜 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateTimeString = "\(meetingDate) \(meetingTime)"
        
        guard let meetingDateTime = dateFormatter.date(from: dateTimeString) else {
            print(" Invalid date format: \(dateTimeString)")
            throw APIError.invalidDateFormat
        }
        
        // 데이터 검증
        guard recruit >= 2 && recruit <= 20 else {
            throw APIError.invalidRecruitNumber
        }
        
        guard cost >= 0 && cost <= 100000 else {
            throw APIError.invalidCost
        }
        
        print("✅ Successfully parsed post data: \(title)")
        
        return GeneratedPostData(
            title: title,
            content: content,
            category: category,
            region: region,
            address: address,
            detailAddress: detailAddress,
            recruit: recruit,
            cost: cost,
            meetingTime: meetingDateTime
        )
    }
}
