import UIKit
import FirebaseFirestore
import FirebaseAuth

class FavoriteViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart.slash")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "찜한 게시물이 없습니다"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .systemGray2
        label.textAlignment = .center
        return label
    }()
    
    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "마음에 드는 게시물에 ♥를 눌러보세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray3
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Properties
    private var allFavoritePosts: [Post] = [] // 모든 찜한 게시물 (원본)
    private var filteredFavoritePosts: [Post] = [] // 필터링된 찜한 게시물 (화면에 표시)
    
    // 정렬 및 필터 상태
    private var currentSortOption: SortOption = .latest
    private var currentFilterOption: FilterOption = .all
    
    private enum SortOption: String, CaseIterable {
        case latest = "최신순"
        case oldest = "오래된순"
        case titleAsc = "가나다순"
        case titleDesc = "가나다 역순"
    }
    
    private enum FilterOption: String, CaseIterable {
        case all = "전체보기"
        case friendship = "친목"
        case sports = "스포츠"
        case study = "스터디"
        case travel = "여행"
        case partTime = "알바"
        case game = "게임"
        case volunteer = "봉사"
        case fitness = "헬스"
        case music = "음악"
        case etc = "기타"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupNavigationBar()
        setupEmptyStateView()
        loadFavoriteData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 데이터 새로고침
        loadFavoriteData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "찜한 게시물"
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationBar() {
        // 정렬 버튼 (왼쪽)
        let sortButton = UIBarButtonItem(
            title: "정렬",
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )
        navigationItem.leftBarButtonItem = sortButton
        
        // 필터 버튼 (오른쪽)
        let filterButton = UIBarButtonItem(
            title: "필터",
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        navigationItem.rightBarButtonItem = filterButton
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostTableViewCell")
        tableView.rowHeight = 120
        
        // 새로고침 컨트롤 추가
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptySubtitleLabel)
        
        [emptyStateView, emptyImageView, emptyTitleLabel, emptySubtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Empty State View
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Empty Image
            emptyImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Empty Title
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 16),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            // Empty Subtitle
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 8),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptySubtitleLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func sortButtonTapped() {
        showSortOptions()
    }
    
    @objc private func filterButtonTapped() {
        showFilterOptions()
    }
    
    @objc private func refreshData() {
        loadFavoriteData()
    }
    
    // MARK: - 정렬 옵션 표시
    private func showSortOptions() {
        let alert = UIAlertController(title: "정렬 방식 선택", message: nil, preferredStyle: .actionSheet)
        
        for sortOption in SortOption.allCases {
            let action = UIAlertAction(title: sortOption.rawValue, style: .default) { [weak self] _ in
                self?.applySorting(sortOption)
            }
            
            // 현재 선택된 옵션에 체크마크 표시
            if sortOption == currentSortOption {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - 필터 옵션 표시
    private func showFilterOptions() {
        let alert = UIAlertController(title: "카테고리 필터", message: nil, preferredStyle: .actionSheet)
        
        for filterOption in FilterOption.allCases {
            let action = UIAlertAction(title: filterOption.rawValue, style: .default) { [weak self] _ in
                self?.applyFilter(filterOption)
            }
            
            // 현재 선택된 옵션에 체크마크 표시
            if filterOption == currentFilterOption {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - 정렬 적용
    private func applySorting(_ sortOption: SortOption) {
        currentSortOption = sortOption
        
        switch sortOption {
        case .latest:
            filteredFavoritePosts.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            filteredFavoritePosts.sort { $0.createdAt < $1.createdAt }
        case .titleAsc:
            filteredFavoritePosts.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleDesc:
            filteredFavoritePosts.sort { $0.title.localizedCompare($1.title) == .orderedDescending }
        }
        
        updateNavigationTitle()
        tableView.reloadData()
    }
    
    // MARK: - 필터 적용
    private func applyFilter(_ filterOption: FilterOption) {
        currentFilterOption = filterOption
        
        if filterOption == .all {
            filteredFavoritePosts = allFavoritePosts
        } else {
            filteredFavoritePosts = allFavoritePosts.filter { $0.category == filterOption.rawValue }
        }
        
        // 필터 적용 후 현재 정렬 옵션도 다시 적용
        applySorting(currentSortOption)
        updateEmptyState()
    }
    
    // MARK: - 네비게이션 타이틀 업데이트
    private func updateNavigationTitle() {
        var titleComponents: [String] = ["찜한 게시물"]
        
        if currentFilterOption != .all {
            titleComponents.append("(\(currentFilterOption.rawValue))")
        }
        
        title = titleComponents.joined(separator: " ")
    }
    
    // MARK: - 빈 상태 업데이트
    private func updateEmptyState() {
        let isEmpty = filteredFavoritePosts.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            if currentFilterOption == .all {
                emptyTitleLabel.text = "찜한 게시물이 없습니다"
                emptySubtitleLabel.text = "마음에 드는 게시물에 ♥를 눌러보세요"
            } else {
                emptyTitleLabel.text = "\(currentFilterOption.rawValue) 카테고리에\n찜한 게시물이 없습니다"
                emptySubtitleLabel.text = "다른 카테고리를 확인해보세요"
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadFavoriteData() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("로그인된 사용자가 없습니다")
            tableView.refreshControl?.endRefreshing()
            updateEmptyState()
            return
        }
        
        let db = Firestore.firestore()
        
        // 1. 먼저 모든 게시물을 가져옴
        db.collection("posts").getDocuments { [weak self] (querySnapshot, error) in
            DispatchQueue.main.async {
                self?.tableView.refreshControl?.endRefreshing()
                
                if let error = error {
                    print("Error getting posts: \(error)")
                    self?.showErrorAlert(message: "데이터를 불러오는데 실패했습니다.")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    self?.allFavoritePosts = []
                    self?.filteredFavoritePosts = []
                    self?.updateEmptyState()
                    return
                }
                
                // 2. 각 게시물에 대해 현재 사용자가 찜했는지 확인
                let group = DispatchGroup()
                var favoritePosts: [Post] = []
                
                for document in documents {
                    group.enter()
                    
                    // favorite 컬렉션에서 현재 사용자 문서 확인
                    document.reference.collection("favorite").document(currentUserId).getDocument { favoriteDoc, error in
                        defer { group.leave() }
                        
                        // 찜한 게시물인지 확인
                        guard favoriteDoc?.exists == true else { return }
                        
                        // 게시물 데이터 파싱
                        let data = document.data()
                        
                        if let title = data["title"] as? String,
                           let content = data["content"] as? String,
                           let tag = data["tag"] as? String,
                           let recruit = data["recruit"] as? Int,
                           let address = data["address"] as? String,
                           let detailAddress = data["detailAddress"] as? String,
                           let category = data["category"] as? String,
                           let cost = data["cost"] as? Int,
                           let authorId = data["id"] as? String {
                            
                            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            let meetingTime = (data["meetingTime"] as? Timestamp)?.dateValue() ?? Date()
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
                            
                            favoritePosts.append(post)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.allFavoritePosts = favoritePosts
                    // 현재 필터 옵션 적용
                    self?.applyFilter(self?.currentFilterOption ?? .all)
                    
                    print("찜한 게시물 \(favoritePosts.count)개 로드 완료!")
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFavoritePosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        let post = filteredFavoritePosts[indexPath.row]
        
        cell.configure(with: post)
        cell.delegate = self  // delegate 설정
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPost = filteredFavoritePosts[indexPath.row]
        
        let detailVC = PostDetailViewController(post: selectedPost)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // 좋아요 상태가 변경되었을 때 해당 게시물을 찜 목록에서 제거
    func refreshCell(for postId: String) {
        // 찜 해제된 경우 목록에서 제거
        if let index = filteredFavoritePosts.firstIndex(where: { $0.id == postId }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 약간의 딜레이 후 제거
                self.loadFavoriteData() // 전체 데이터 새로고침
            }
        }
    }
}

// MARK: - PostTableViewCellDelegate
extension FavoriteViewController: PostTableViewCellDelegate {
    func postCell(_ cell: PostTableViewCell, didToggleFavoriteFor post: Post) {
        // 찜 상태 변경 시 목록 새로고침
        print("찜 상태 변경됨: \(post.title)")
        
        // 찜 해제된 경우를 위해 약간의 딜레이 후 새로고침
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadFavoriteData()
        }
    }
}
