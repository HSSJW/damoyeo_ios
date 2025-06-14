import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol PostTableViewCellDelegate: AnyObject {
    func postCell(_ cell: PostTableViewCell, didToggleFavoriteFor post: Post)
}

class PostTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    weak var delegate: PostTableViewCellDelegate?
    private var post: Post?
    private var isFavorited = false
    private var participantsCount = 0
    private var currentImageURL: String = "" // 현재 로딩 중인 이미지 URL 추적
    
    // MARK: - UI Components
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.numberOfLines = 2
        return label
    }()
    
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let participantsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 셀 재사용 처리 (중복 제거하고 개선)
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 기본값으로 초기화
        postImageView.image = UIImage(systemName: "photo")
        post = nil
        isFavorited = false
        participantsCount = 0
        currentImageURL = ""
        
        // 텍스트 초기화
        titleLabel.text = nil
        contentLabel.text = nil
        tagLabel.text = nil
        participantsLabel.text = nil
        
        // 좋아요 버튼 초기화
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        
        [postImageView, titleLabel, contentLabel, tagLabel, participantsLabel, favoriteButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // 이미지
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            postImageView.widthAnchor.constraint(equalToConstant: 80),
            postImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // 좋아요 버튼
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 제목
            titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // 내용
            contentLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // 지역
            tagLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            tagLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
            
            // 참여인원
            participantsLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            participantsLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 2),
            participantsLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
        
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with post: Post) {
        self.post = post
        
        titleLabel.text = post.title
        
        // 내용이 너무 길면 자르기
        if post.content.count > 50 {
            let index = post.content.index(post.content.startIndex, offsetBy: 50)
            contentLabel.text = String(post.content[..<index]) + "..."
        } else {
            contentLabel.text = post.content
        }
        
        tagLabel.text = "지역: \(post.tag)"
        
        // 개선된 이미지 로딩 (ImageCacheManager 사용)
        let imageUrlString = post.imageUrls.first ?? post.imageUrl
        currentImageURL = imageUrlString
        
        let placeholder = UIImage(systemName: "photo")
        postImageView.loadImage(from: imageUrlString, placeholder: placeholder)
        
        // 좋아요 상태 및 참여인원 로드
        loadFavoriteStatus()
        loadParticipantsCount()
    }
    
    // MARK: - 기존 loadImage 메서드 제거하고 ImageCacheManager 사용
    // loadImage 메서드는 제거 - UIImageView extension에서 처리
    
    private func loadFavoriteStatus() {
        guard let post = post, let currentUserId = Auth.auth().currentUser?.uid else {
            updateFavoriteButton()
            return
        }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("favorite").document(currentUserId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isFavorited = document?.exists ?? false
                self?.updateFavoriteButton()
            }
        }
    }
    
    private func loadParticipantsCount() {
        guard let post = post else { return }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("proposers").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.participantsCount = snapshot?.documents.count ?? 0
                self?.updateParticipantsLabel()
            }
        }
    }
    
    private func updateFavoriteButton() {
        let imageName = isFavorited ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func updateParticipantsLabel() {
        guard let post = post else { return }
        participantsLabel.text = "참여인원: \(participantsCount)/\(post.recruit)"
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let post = post else { return }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            // 로그인 필요 알림은 delegate를 통해 처리
            return
        }
        
        let db = Firestore.firestore()
        let favoriteRef = db.collection("posts").document(post.id).collection("favorite").document(currentUserId)
        
        if isFavorited {
            // 좋아요 취소
            favoriteRef.delete { [weak self] error in
                if let error = error {
                    print("좋아요 취소 실패: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.isFavorited = false
                    self?.updateFavoriteButton()
                    
                    if let post = self?.post {
                        self?.delegate?.postCell(self!, didToggleFavoriteFor: post)
                    }
                }
            }
        } else {
            // 좋아요 추가
            favoriteRef.setData([
                "user_id": currentUserId,
                "createdAt": Timestamp(date: Date())
            ]) { [weak self] error in
                if let error = error {
                    print("좋아요 추가 실패: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.isFavorited = true
                    self?.updateFavoriteButton()
                    
                    if let post = self?.post {
                        self?.delegate?.postCell(self!, didToggleFavoriteFor: post)
                    }
                }
            }
        }
    }
}
