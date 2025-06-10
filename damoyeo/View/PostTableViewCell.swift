//
//  PostTableViewCell.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class PostTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.numberOfLines = 2
        return label
    }()
    
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemOrange
        label.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private let participantsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray2
        return label
    }()
    
    // 좋아요 버튼
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .custom)  // .system 대신 .custom 사용
        
        // Configuration 사용
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "heart")
        config.baseForegroundColor = .systemGray4
        config.background.backgroundColor = .clear  // 배경색 명시적으로 clear
        
        button.configuration = config
        button.backgroundColor = .clear  // 추가 안전장치
        
        return button
    }()
    
    // MARK: - Properties
    private var currentPost: Post?
    private var isLiked = false
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(postImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(participantsLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(favoriteButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        [postImageView, titleLabel, contentLabel, tagLabel, categoryLabel,
         participantsLabel, dateLabel, favoriteButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Post Image
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            postImageView.widthAnchor.constraint(equalToConstant: 80),
            postImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Favorite Button
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -12),
            
            // Content Label
            contentLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -12),
            
            // Date Label - contentLabel 바로 아래로 이동
            dateLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            dateLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            
            // Tag Label - dateLabel 아래, 하단에 위치 (categoryLabel과 같은 높이)
            tagLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            tagLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            tagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            tagLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Category Label - tagLabel과 같은 높이, tagLabel 오른쪽에 위치
            categoryLabel.leadingAnchor.constraint(equalTo: tagLabel.trailingAnchor, constant: 6),
            categoryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            categoryLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Participants Label - 맨 오른쪽, tagLabel과 categoryLabel과 같은 높이
            participantsLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -12),
            participantsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupActions() {
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with post: Post) {
        currentPost = post
        titleLabel.text = post.title
        
        // 내용 요약 표시
        let maxLength = 50
        if post.content.count > maxLength {
            let index = post.content.index(post.content.startIndex, offsetBy: maxLength)
            contentLabel.text = String(post.content[..<index]) + "..."
        } else {
            contentLabel.text = post.content
        }
        
        tagLabel.text = " \(post.tag) "  // 양옆에 여백 추가
        categoryLabel.text = " \(post.category) "  // 양옆에 여백 추가
        
        // 날짜 포맷팅
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        dateLabel.text = formatter.string(from: post.meetingTime)
        
        // 이미지 설정
        if !post.imageUrls.isEmpty {
            loadImage(from: post.imageUrls.first!)
        } else {
            postImageView.image = UIImage(systemName: "photo")
            postImageView.tintColor = .systemGray3
        }
        
        // 로그인 상태에 따라 좋아요 버튼 표시/숨김
        favoriteButton.isHidden = Auth.auth().currentUser == nil
        
        // 참가자 수와 좋아요 상태 로드
        loadParticipantsCount()
        loadFavoriteStatus()
    }
    
    // MARK: - Firebase Methods
    private func loadParticipantsCount() {
        guard let post = currentPost else { return }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("proposers").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                let count = snapshot?.documents.count ?? 0
                // 새로운 형식으로 변경: "참가인원 : (1/5)"
                self?.participantsLabel.text = "참가인원 : (\(count)/\(post.recruit))"
            }
        }
    }
    
    private func loadFavoriteStatus() {
        guard let post = currentPost,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("favorite").document(currentUserId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLiked = document?.exists ?? false
                self?.updateFavoriteButtonAppearance()
            }
        }
    }
    
    // 좋아요 버튼 색상 업데이트 메서드 추가
    private func updateFavoriteButtonAppearance() {
        var config = favoriteButton.configuration
        
        if isLiked {
            config?.image = UIImage(systemName: "heart.fill")
            config?.baseForegroundColor = .systemRed
        } else {
            config?.image = UIImage(systemName: "heart")
            config?.baseForegroundColor = .systemGray4
        }
        
        favoriteButton.configuration = config
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let post = currentPost,
              let currentUserId = Auth.auth().currentUser?.uid else {
            print("로그인이 필요합니다.")
            return
        }
        
        // 버튼 비활성화 (중복 탭 방지)
        favoriteButton.isEnabled = false
        
        let db = Firestore.firestore()
        let favoriteRef = db.collection("posts").document(post.id).collection("favorite").document(currentUserId)
        
        if isLiked {
            // 좋아요 취소
            favoriteRef.delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.favoriteButton.isEnabled = true
                    
                    if let error = error {
                        print("좋아요 취소 실패: \(error.localizedDescription)")
                        return
                    }
                    
                    self?.isLiked = false
                    self?.updateFavoriteButtonAppearance()
                    
                    // 애니메이션 효과
                    UIView.animate(withDuration: 0.1, animations: {
                        self?.favoriteButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    }) { _ in
                        UIView.animate(withDuration: 0.1) {
                            self?.favoriteButton.transform = .identity
                        }
                    }
                }
            }
        } else {
            // 좋아요 추가
            favoriteRef.setData([
                "user_id": currentUserId,
                "createdAt": Timestamp()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.favoriteButton.isEnabled = true
                    
                    if let error = error {
                        print("좋아요 추가 실패: \(error.localizedDescription)")
                        return
                    }
                    
                    self?.isLiked = true
                    self?.updateFavoriteButtonAppearance()
                    
                    // 애니메이션 효과
                    UIView.animate(withDuration: 0.1, animations: {
                        self?.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }) { _ in
                        UIView.animate(withDuration: 0.1) {
                            self?.favoriteButton.transform = .identity
                        }
                    }
                }
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            postImageView.image = UIImage(systemName: "photo")
            postImageView.tintColor = .systemGray3
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.postImageView.image = UIImage(systemName: "photo")
                    self?.postImageView.tintColor = .systemGray3
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.postImageView.image = image
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.image = nil
        titleLabel.text = nil
        contentLabel.text = nil
        tagLabel.text = nil
        categoryLabel.text = nil
        participantsLabel.text = nil
        dateLabel.text = nil
        
        // 버튼 초기화
        var config = favoriteButton.configuration
        config?.image = UIImage(systemName: "heart")
        config?.baseForegroundColor = .systemGray4
        favoriteButton.configuration = config
        
        isLiked = false
        currentPost = nil
        favoriteButton.isEnabled = true
    }
}
