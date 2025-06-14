//
//  ImageCacheManager.swift
//  damoyeo
//
//  Created by 송진우 on 6/15/25.
//

import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private init() {}
    
    private let cache = NSCache<NSString, UIImage>()
    private let downloadQueue = DispatchQueue(label: "imageDownloadQueue", qos: .utility, attributes: .concurrent)
    
    func loadImage(from urlString: String, placeholder: UIImage? = nil, completion: @escaping (UIImage?) -> Void) {
        // 빈 URL 체크
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(placeholder)
            }
            return
        }
        
        let cacheKey = NSString(string: urlString)
        
        // 캐시에서 확인
        if let cachedImage = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // 플레이스홀더 먼저 표시
        DispatchQueue.main.async {
            completion(placeholder)
        }
        
        // 백그라운드에서 다운로드
        downloadQueue.async { [weak self] in
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(placeholder)
                }
                return
            }
            
            // 캐시에 저장
            self?.cache.setObject(image, forKey: cacheKey)
            
            // 메인 스레드에서 결과 반환
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func removeImage(for urlString: String) {
        let cacheKey = NSString(string: urlString)
        cache.removeObject(forKey: cacheKey)
    }
}

// MARK: - UIImageView Extension
extension UIImageView {
    func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        // 현재 이미지 URL 저장 (셀 재사용 대응)
        let currentURLString = urlString
        
        ImageCacheManager.shared.loadImage(from: urlString, placeholder: placeholder) { [weak self] image in
            // 셀이 재사용되어 다른 URL로 변경되었는지 확인
            guard let self = self else { return }
            
            // 현재 요청과 동일한 URL인 경우만 이미지 설정
            if urlString == currentURLString {
                self.image = image
            }
        }
    }
}
