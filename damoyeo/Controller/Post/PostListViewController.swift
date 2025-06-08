import UIKit
import FirebaseFirestore

class PostListViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    // MARK: - Properties
    private var posts: [Post] = [] // 임시로 빈 배열
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupNavigationBar()
        loadFirebaseData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "모집 게시물"
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationBar() {
        // Sort 버튼 (왼쪽)
        let sortButton = UIBarButtonItem(
            title: "Sort",
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )
        navigationItem.leftBarButtonItem = sortButton
        
        // Filter 버튼과 Add 버튼 (오른쪽)
        let filterButton = UIBarButtonItem(
            title: "Filter",
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPostTapped)
        )
        navigationItem.rightBarButtonItems = [addButton, filterButton]
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 커스텀 셀 등록
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostTableViewCell")
        
        // 셀 높이 설정
        tableView.rowHeight = 104
    }
    
    // MARK: - Actions
    @objc private func sortButtonTapped() {
        print("Sort 버튼 탭됨")
        // TODO: 정렬 기능 구현
    }
    
    @objc private func filterButtonTapped() {
        print("Filter 버튼 탭됨")
        // TODO: 필터 기능 구현
    }
    
    @objc private func addPostTapped() {
        print("게시물 작성 버튼 탭됨")
        // TODO: 게시물 작성 화면으로 이동
    }
    
    // MARK: - Data
    private func loadFirebaseData() {
        let db = Firestore.firestore()
        
        db.collection("posts").getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            var loadedPosts: [Post] = []
            
            for document in documents {
                let data = document.data()
                
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
            
            DispatchQueue.main.async {
                self?.posts = loadedPosts
                self?.tableView.reloadData()
                print("Firebase에서 \(loadedPosts.count)개 게시물 로드 완료!")
            }
        }
    }
}

extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count // 실제 posts 배열 개수
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        let post = posts[indexPath.row]
        
        cell.configure(with: post)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPost = posts[indexPath.row]
        
        let detailVC = PostDetailViewController(post: selectedPost)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
