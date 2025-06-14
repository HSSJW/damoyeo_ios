import UIKit
import FirebaseFirestore
import FirebaseAuth

class PostListViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    // 플로팅 액션 버튼
    private let floatingActionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        return button
    }()
    
    // MARK: - Properties
    private var allPosts: [Post] = [] // 모든 게시물 (원본)
    private var filteredPosts: [Post] = [] // 필터링된 게시물 (화면에 표시)
    
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
        setupFloatingActionButton()
        loadFirebaseData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 데이터 새로고침
        loadFirebaseData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "모집 게시물"
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
    
    private func setupFloatingActionButton() {
        view.addSubview(floatingActionButton)
        floatingActionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            floatingActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatingActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            floatingActionButton.widthAnchor.constraint(equalToConstant: 56),
            floatingActionButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        floatingActionButton.addTarget(self, action: #selector(addPostTapped), for: .touchUpInside)
        floatingActionButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        floatingActionButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Actions
    @objc private func sortButtonTapped() {
        showSortOptions()
    }
    
    @objc private func filterButtonTapped() {
        showFilterOptions()
    }
    
    @objc private func addPostTapped() {
        guard Auth.auth().currentUser != nil else {
            showLoginAlert()
            return
        }
        
        let createPostVC = CreatePostViewController()
        let navController = UINavigationController(rootViewController: createPostVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func refreshData() {
        loadFirebaseData()
    }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.floatingActionButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.floatingActionButton.transform = .identity
        }
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
            filteredPosts.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            filteredPosts.sort { $0.createdAt < $1.createdAt }
        case .titleAsc:
            filteredPosts.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleDesc:
            filteredPosts.sort { $0.title.localizedCompare($1.title) == .orderedDescending }
        }
        
        updateNavigationTitle()
        tableView.reloadData()
    }
    
    // MARK: - 필터 적용
    private func applyFilter(_ filterOption: FilterOption) {
        currentFilterOption = filterOption
        
        if filterOption == .all {
            filteredPosts = allPosts
        } else {
            filteredPosts = allPosts.filter { $0.category == filterOption.rawValue }
        }
        
        // 필터 적용 후 현재 정렬 옵션도 다시 적용
        applySorting(currentSortOption)
    }
    
    // MARK: - 네비게이션 타이틀 업데이트
    private func updateNavigationTitle() {
        var titleComponents: [String] = ["모집 게시물"]
        
        if currentFilterOption != .all {
            titleComponents.append("(\(currentFilterOption.rawValue))")
        }
        
        title = titleComponents.joined(separator: " ")
    }
    
    // MARK: - 로그인 알림
    private func showLoginAlert() {
        let alert = UIAlertController(
            title: "로그인 필요",
            message: "게시물을 작성하려면 로그인이 필요합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Data Loading
    private func loadFirebaseData() {
        let db = Firestore.firestore()
        
        db.collection("posts").getDocuments { [weak self] (querySnapshot, error) in
            DispatchQueue.main.async {
                // 새로고침 컨트롤 종료
                self?.tableView.refreshControl?.endRefreshing()
                
                if let error = error {
                    print("Error getting documents: \(error)")
                    self?.showErrorAlert(message: "데이터를 불러오는데 실패했습니다.")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    self?.allPosts = []
                    self?.filteredPosts = []
                    self?.tableView.reloadData()
                    return
                }
                
                var loadedPosts: [Post] = []
                
                for document in documents {
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
                        
                        loadedPosts.append(post)
                    }
                }
                
                self?.allPosts = loadedPosts
                // 현재 필터 옵션 적용
                self?.applyFilter(self?.currentFilterOption ?? .all)
                
                print("Firebase에서 \(loadedPosts.count)개 게시물 로드 완료!")
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
extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredPosts.isEmpty {
            // 빈 상태 메시지 표시
            let emptyLabel = UILabel()
            emptyLabel.text = currentFilterOption == .all ? "게시물이 없습니다" : "\(currentFilterOption.rawValue) 카테고리에 게시물이 없습니다"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.font = .systemFont(ofSize: 16)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        
        return filteredPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        let post = filteredPosts[indexPath.row]
        
        cell.configure(with: post)
        cell.delegate = self  // delegate 설정
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPost = filteredPosts[indexPath.row]
        
        let detailVC = PostDetailViewController(post: selectedPost)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // 좋아요 상태가 변경되었을 때 해당 셀만 갱신
    func refreshCell(for postId: String) {
        if let index = filteredPosts.firstIndex(where: { $0.id == postId }) {
            let indexPath = IndexPath(row: index, section: 0)
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK: - PostTableViewCellDelegate
extension PostListViewController: PostTableViewCellDelegate {
    func postCell(_ cell: PostTableViewCell, didToggleFavoriteFor post: Post) {
        // 좋아요 상태 변경 시 필요한 처리 (예: 업데이트 로그 등)
        print("좋아요 상태 변경됨: \(post.title)")
    }
}
