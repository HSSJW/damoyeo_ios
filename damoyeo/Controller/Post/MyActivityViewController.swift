import UIKit
import FirebaseAuth
import FirebaseFirestore

class MyActivityViewController: UIViewController {
    
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let items = ["내 모집", "참가한 모집"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "게시물이 없습니다"
        label.textAlignment = .center
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var userId: String
    private var myPosts: [Post] = []
    private var participatedPosts: [Post] = []
    private var currentMode: ActivityMode = .myPosts {
        didSet {
            tableView.reloadData()
            updateEmptyState()
        }
    }
    
    private enum ActivityMode {
        case myPosts
        case participatedPosts
        
        var posts: [Post] {
            switch self {
            case .myPosts:
                return []  // 이 값은 실제로는 사용되지 않음
            case .participatedPosts:
                return []  // 이 값은 실제로는 사용되지 않음
            }
        }
    }
    
    // MARK: - Initialization
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData() // 화면이 나타날 때마다 데이터 새로고침
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "활동 내역"
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(loadingIndicator)
        
        setupTableView()
        setupConstraints()
        setupActions()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
    }
    
    private func setupConstraints() {
        [segmentedControl, tableView, emptyStateLabel, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        currentMode = segmentedControl.selectedSegmentIndex == 0 ? .myPosts : .participatedPosts
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadingIndicator.startAnimating()
        
        let group = DispatchGroup()
        
        // 내가 작성한 게시물 로드
        group.enter()
        loadMyPosts { [weak self] in
            group.leave()
        }
        
        // 내가 참가한 게시물 로드
        group.enter()
        loadParticipatedPosts { [weak self] in
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }
    
    private func loadMyPosts(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("내 게시물 로드 실패: \(error.localizedDescription)")
                    } else if let documents = snapshot?.documents {
                        var loadedPosts: [Post] = []
                        
                        for document in documents {
                            let data = document.data()
                            
                            // Firestore 데이터를 Post 모델로 변환 (PostListViewController와 동일한 방식)
                            if let title = data["title"] as? String,
                               let content = data["content"] as? String,
                               let tag = data["tag"] as? String,
                               let recruit = data["recruit"] as? Int,
                               let address = data["address"] as? String,
                               let detailAddress = data["detailAddress"] as? String,
                               let category = data["category"] as? String,
                               let cost = data["cost"] as? Int,
                               let authorId = data["id"] as? String {
                                
                                // 날짜 처리
                                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                                let meetingTime = (data["meetingTime"] as? Timestamp)?.dateValue() ?? Date()
                                
                                // 이미지 URL 처리
                                let imageUrls = data["imageUrls"] as? [String] ?? []
                                let imageUrl = data["imageUrl"] as? String ?? ""
                                
                                let post = Post(
                                    id: document.documentID,
                                    title: title,
                                    content: content,
                                    tag: tag,
                                    recruit: recruit,
                                    createdAt: createdAt,
                                    imageUrl: imageUrl,
                                    imageUrls: imageUrls,
                                    address: address,
                                    detailAddress: detailAddress,
                                    category: category,
                                    cost: cost,
                                    meetingTime: meetingTime,
                                    authorId: authorId
                                )
                                
                                loadedPosts.append(post)
                            }
                        }
                        
                        self?.myPosts = loadedPosts
                    }
                    completion()
                }
            }
    }
    
    private func loadParticipatedPosts(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        var participatedPostIds: [String] = []
        
        // 1. 먼저 내가 참가한 게시물 ID들을 찾기
        db.collection("posts").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("참가한 게시물 로드 실패: \(error.localizedDescription)")
                DispatchQueue.main.async { completion() }
                return
            }
            
            let group = DispatchGroup()
            
            for document in snapshot?.documents ?? [] {
                group.enter()
                
                // 각 게시물의 proposers 컬렉션에서 내 ID 확인
                document.reference.collection("proposers").document(self.userId).getDocument { proposerDoc, _ in
                    if proposerDoc?.exists == true {
                        participatedPostIds.append(document.documentID)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                // 2. 참가한 게시물들의 상세 정보 가져오기
                self.loadPostDetails(postIds: participatedPostIds) { posts in
                    self.participatedPosts = posts
                    completion()
                }
            }
        }
    }
    
    private func loadPostDetails(postIds: [String], completion: @escaping ([Post]) -> Void) {
        guard !postIds.isEmpty else {
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        var posts: [Post] = []
        let group = DispatchGroup()
        
        for postId in postIds {
            group.enter()
            db.collection("posts").document(postId).getDocument { doc, error in
                if let doc = doc, let data = doc.data() {
                    // Firestore 데이터를 Post 모델로 변환
                    if let title = data["title"] as? String,
                       let content = data["content"] as? String,
                       let tag = data["tag"] as? String,
                       let recruit = data["recruit"] as? Int,
                       let address = data["address"] as? String,
                       let detailAddress = data["detailAddress"] as? String,
                       let category = data["category"] as? String,
                       let cost = data["cost"] as? Int,
                       let authorId = data["id"] as? String {
                        
                        // 날짜 처리
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        let meetingTime = (data["meetingTime"] as? Timestamp)?.dateValue() ?? Date()
                        
                        // 이미지 URL 처리
                        let imageUrls = data["imageUrls"] as? [String] ?? []
                        let imageUrl = data["imageUrl"] as? String ?? ""
                        
                        let post = Post(
                            id: doc.documentID,
                            title: title,
                            content: content,
                            tag: tag,
                            recruit: recruit,
                            createdAt: createdAt,
                            imageUrl: imageUrl,
                            imageUrls: imageUrls,
                            address: address,
                            detailAddress: detailAddress,
                            category: category,
                            cost: cost,
                            meetingTime: meetingTime,
                            authorId: authorId
                        )
                        
                        posts.append(post)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(posts)
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = currentPosts.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        emptyStateLabel.text = currentMode == .myPosts ? "작성한 게시물이 없습니다" : "참가한 게시물이 없습니다"
    }
    
    private var currentPosts: [Post] {
        return currentMode == .myPosts ? myPosts : participatedPosts
    }
}

// MARK: - TableView DataSource & Delegate
extension MyActivityViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        
        let post = currentPosts[indexPath.row]
        cell.configure(with: post)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let post = currentPosts[indexPath.row]
        let detailVC = PostDetailViewController(post: post)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
