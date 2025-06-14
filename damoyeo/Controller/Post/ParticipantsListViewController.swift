import UIKit
import FirebaseFirestore
import FirebaseAuth

class ParticipantsListViewController: UIViewController {
    
    // MARK: - Properties
    private let postId: String
    private let participantsCount: Int
    private var participants: [(userId: String, nickname: String, profileImage: String?)] = []
    
    // 채팅 콜백
    var onParticipantChatTapped: ((String) -> Void)?
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "참여한 인원이 없습니다."
        label.textColor = .systemGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    init(postId: String, participantsCount: Int) {
        self.postId = postId
        self.participantsCount = participantsCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadParticipants()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "참여 인원 목록"
        
        // 네비게이션 바 설정
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissViewController)
        )
        
        // 테이블뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ParticipantCell.self, forCellReuseIdentifier: "ParticipantCell")
        tableView.rowHeight = 70
        
        // 뷰 추가
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        // 제약조건 설정
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadParticipants() {
        let db = Firestore.firestore()
        
        // 참가자 목록 가져오기
        db.collection("posts").document(postId).collection("proposers").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error loading participants: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async {
                    self?.updateEmptyState()
                }
                return
            }
            
            let userIds = documents.compactMap { $0.data()["user_id"] as? String }
            self?.loadUserDetails(for: userIds)
        }
    }
    
    private func loadUserDetails(for userIds: [String]) {
        guard !userIds.isEmpty else {
            DispatchQueue.main.async {
                self.updateEmptyState()
            }
            return
        }
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var loadedParticipants: [(userId: String, nickname: String, profileImage: String?)] = []
        
        for userId in userIds {
            group.enter()
            
            db.collection("users").document(userId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading user \(userId): \(error)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("User document does not exist: \(userId)")
                    return
                }
                
                let data = document.data()
                let nickname = data?["user_nickname"] as? String ?? "사용자"
                let profileImage = data?["profile_image"] as? String
                
                loadedParticipants.append((
                    userId: userId,
                    nickname: nickname,
                    profileImage: profileImage
                ))
            }
        }
        
        group.notify(queue: .main) {
            self.participants = loadedParticipants.sorted { $0.nickname < $1.nickname }
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = participants.isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Actions
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ParticipantsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell
        let participant = participants[indexPath.row]
        
        cell.configure(
            nickname: participant.nickname,
            profileImageUrl: participant.profileImage,
            onChatTapped: { [weak self] in
                self?.onParticipantChatTapped?(participant.userId)
            }
        )
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ParticipantsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let participant = participants[indexPath.row]
        
        // 사용자 프로필로 이동하거나 추가 정보 표시
        // TODO: 필요시 구현
        print("Selected participant: \(participant.nickname)")
    }
}

// MARK: - ParticipantCell
class ParticipantCell: UITableViewCell {
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 25
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "message"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var onChatTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(chatButton)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nicknameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nicknameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatButton.leadingAnchor, constant: -12),
            
            chatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chatButton.widthAnchor.constraint(equalToConstant: 44),
            chatButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(nickname: String, profileImageUrl: String?, onChatTapped: @escaping () -> Void) {
        nicknameLabel.text = nickname
        self.onChatTapped = onChatTapped
        
        // 프로필 이미지 로드
        if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
            loadProfileImage(from: profileImageUrl)
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray3
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
                    self?.profileImageView.tintColor = .systemGray3
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Actions
    @objc private func chatButtonTapped() {
        onChatTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        nicknameLabel.text = nil
        onChatTapped = nil
    }
}
