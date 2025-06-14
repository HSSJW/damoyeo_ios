import UIKit
import Firebase
import FirebaseFirestore

class ChatRoomCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pinIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pin.fill")
        imageView.tintColor = .systemBlue
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(pinIcon)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // Profile Image
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: pinIcon.leadingAnchor, constant: -8),
            
            // Last Message Label
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lastMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            // Pin Icon
            pinIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            pinIcon.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),
            pinIcon.widthAnchor.constraint(equalToConstant: 16),
            pinIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with chatRoom: ChatRoom) {
        let otherUserId = chatRoom.getOtherUserId()
        
        // 상대방 정보 가져오기
        fetchUserInfo(userId: otherUserId) { [weak self] user in
            DispatchQueue.main.async {
                self?.nameLabel.text = user?.userNickname ?? "Unknown"
                
                // 프로필 이미지 로드
                if let profileImageUrl = user?.profileImage,
                   !profileImageUrl.isEmpty,
                   let url = URL(string: profileImageUrl) {
                    self?.loadImage(from: url)
                } else {
                    self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.profileImageView.tintColor = .systemGray3
                }
            }
        }
        
        // 마지막 메시지
        lastMessageLabel.text = chatRoom.lastMessage.isEmpty ? "대화를 시작해보세요!" : chatRoom.lastMessage
        
        // 고정 아이콘
        pinIcon.isHidden = !chatRoom.pinned
        
        // 시간 표시
        if let timestamp = chatRoom.timestamp {
            timeLabel.text = formatTimestamp(timestamp)
        }
    }
    
    private func fetchUserInfo(userId: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user info: \(error)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil)
                return
            }
            
            let user = User(document: document)
            completion(user)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(timestamp) {
            return "어제"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        
        return formatter.string(from: timestamp)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        nameLabel.text = nil
        lastMessageLabel.text = nil
        pinIcon.isHidden = true
        timeLabel.text = nil
    }
}
