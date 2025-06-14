import UIKit
import FirebaseFirestore
import FirebaseAuth

class ParticipantsListViewController: UIViewController {
    
    private let tableView = UITableView()
    private let postId: String
    private let participantsCount: Int
    private var participants: [(userId: String, nickname: String, profileImage: String?)] = []
    
    init(postId: String, participantsCount: Int) {
        self.postId = postId
        self.participantsCount = participantsCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadParticipants()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "참여 인원 목록"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ParticipantTableViewCell.self, forCellReuseIdentifier: "ParticipantCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadParticipants() {
        let db = Firestore.firestore()
        
        // proposers 컬렉션에서 참가자 목록 가져오기
        db.collection("posts").document(postId).collection("proposers").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else {
                print("참가자 목록 로드 실패: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let group = DispatchGroup()
            var loadedParticipants: [(String, String, String?)] = []
            
            for document in documents {
                guard let userId = document.data()["user_id"] as? String else { continue }
                
                group.enter()
                
                // 각 참가자의 사용자 정보 가져오기
                db.collection("users").document(userId).getDocument { userDoc, error in
                    defer { group.leave() }
                    
                    guard let userData = userDoc?.data() else { return }
                    
                    let nickname = userData["user_nickname"] as? String ?? "닉네임 없음"
                    let profileImage = userData["profile_image"] as? String
                    
                    loadedParticipants.append((userId, nickname, profileImage))
                }
            }
            
            group.notify(queue: .main) {
                self?.participants = loadedParticipants
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - ParticipantsListViewController Extensions
extension ParticipantsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if participants.isEmpty {
            // 빈 상태 표시
            let emptyLabel = UILabel()
            emptyLabel.text = "참여 인원이 없습니다"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantTableViewCell
        let participant = participants[indexPath.row]
        cell.configure(userId: participant.userId, nickname: participant.nickname, profileImage: participant.profileImage)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - 참가자 테이블뷰 셀
class ParticipantTableViewCell: UITableViewCell {
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "message"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private var userId: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        [profileImageView, nicknameLabel, chatButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nicknameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            chatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chatButton.widthAnchor.constraint(equalToConstant: 44),
            chatButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
    }
    
    func configure(userId: String, nickname: String, profileImage: String?) {
        self.userId = userId
        nicknameLabel.text = nickname
        
        // 기본 프로필 이미지
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemGray3
        
        // 프로필 이미지 로드
        if let profileImageUrl = profileImage, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else { return }
                
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        }
    }

    @objc private func chatButtonTapped() {
            guard let userId = userId else { return }
            
            // TODO: 채팅 기능 구현
            print("채팅 버튼 탭됨 - 사용자 ID: \(userId)")
            
            // 여기에 채팅 기능을 구현하세요
            // 예시: 채팅방 생성 후 ChatViewController로 이동
        }
    }

