//
//  MyActivityViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseFirestore

class MyActivityViewController: UIViewController {
    
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let items = ["내 모집글", "참가한 모집"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostTableViewCell")
        tableView.rowHeight = 104
        return tableView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private let userId: String
    private var myPosts: [Post] = []
    private var participatedPosts: [Post] = []
    private var currentPosts: [Post] = []
    
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
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "활동 내역"
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
        setupActions()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupConstraints() {
        [segmentedControl, tableView, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadingIndicator.startAnimating()
        
        let group = DispatchGroup()
        
        // 내가 작성한 게시물 로드
        group.enter()
        loadMyPosts {
            group.leave()
        }
        
        // 내가 참가한 게시물 로드
        group.enter()
        loadParticipatedPosts {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.loadingIndicator.stopAnimating()
            self.updateCurrentPosts()
        }
    }
    
    private func loadMyPosts(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("내 게시물 로드 실패: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion()
                    return
                }
                
                var posts: [Post] = []
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
                        
                        posts.append(post)
                    }
                }
                
                DispatchQueue.main.async {
                    self?.myPosts = posts.sorted { $0.createdAt > $1.createdAt }
                    completion()
                }
            }
    }
    
    private func loadParticipatedPosts(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        // 모든 게시물에서 내가 참가한 것들 찾기
        db.collection("posts").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("참가한 게시물 로드 실패: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion()
                return
            }
            
            let group = DispatchGroup()
            var participatedPosts: [Post] = []
            
            for document in documents {
                group.enter()
                
                // 각 게시물의 proposers 서브컬렉션에서 내 ID 확인
                document.reference.collection("proposers").document(self?.userId ?? "").getDocument { proposerDoc, error in
                    if proposerDoc?.exists == true {
                        // 내가 참가한 게시물
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
                            
                            participatedPosts.append(post)
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self?.participatedPosts = participatedPosts.sorted { $0.createdAt > $1.createdAt }
                completion()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        updateCurrentPosts()
    }
    
    private func updateCurrentPosts() {
        if segmentedControl.selectedSegmentIndex == 0 {
            currentPosts = myPosts
        } else {
            currentPosts = participatedPosts
        }
        
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension MyActivityViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        let post = currentPosts[indexPath.row]
        
        cell.configure(with: post)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPost = currentPosts[indexPath.row]
        
        let detailVC = PostDetailViewController(post: selectedPost)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
