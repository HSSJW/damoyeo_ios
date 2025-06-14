//
//  PostDetailViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class PostDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let post: Post
    private var participantsCount = 0
    private var isFavorited = false
    private var favoriteCount = 0
    private var authorId: String = ""
    private var isCurrentUserAuthor = false
    private var isParticipating = false // 현재 사용자의 참가 상태
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 작성자 정보
    private let authorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let authorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 24
        return imageView
    }()
    
    private let authorNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "message"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    // 게시물 이미지
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    // 게시물 정보
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let dateTimeLocationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()
    
    private let costLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let categoryTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    // 하단 액션 영역
    private let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    private let favoriteCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private let participateButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    // MARK: - Initialization
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // viewDidLoad에서 호출할 메서드 추가
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithPost()
        loadPostDetails()
        loadParticipantsData()
        loadFavoriteData()
        checkUserFavoriteStatus()
        checkUserParticipationStatus() // 추가
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "게시물 상세" // 네비게이션 타이틀 설정
        
        // ScrollView 설정
        view.addSubview(scrollView)
        view.addSubview(bottomView)
        scrollView.addSubview(contentView)
        
        // 작성자 정보
        contentView.addSubview(authorView)
        authorView.addSubview(authorImageView)
        authorView.addSubview(authorNameLabel)
        authorView.addSubview(chatButton)
        
        // 게시물 정보
        contentView.addSubview(postImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateTimeLocationLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(costLabel)
        contentView.addSubview(categoryTagLabel)
        
        // 하단 액션
        bottomView.addSubview(favoriteButton)
        bottomView.addSubview(favoriteCountLabel)
        bottomView.addSubview(participateButton)
        
        setupConstraints()
        setupActions()
    }
    
    private func setupConstraints() {
        [scrollView, bottomView, contentView, authorView, authorImageView, authorNameLabel, chatButton,
         postImageView, titleLabel, dateTimeLocationLabel, contentLabel, costLabel, categoryTagLabel,
         favoriteButton, favoriteCountLabel, participateButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            
            // Bottom View
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 80),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 작성자 영역
            authorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            authorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            authorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            authorView.heightAnchor.constraint(equalToConstant: 70),
            
            authorImageView.leadingAnchor.constraint(equalTo: authorView.leadingAnchor, constant: 16),
            authorImageView.centerYAnchor.constraint(equalTo: authorView.centerYAnchor),
            authorImageView.widthAnchor.constraint(equalToConstant: 48),
            authorImageView.heightAnchor.constraint(equalToConstant: 48),
            
            authorNameLabel.leadingAnchor.constraint(equalTo: authorImageView.trailingAnchor, constant: 12),
            authorNameLabel.centerYAnchor.constraint(equalTo: authorView.centerYAnchor),
            
            chatButton.trailingAnchor.constraint(equalTo: authorView.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: authorView.centerYAnchor),
            chatButton.widthAnchor.constraint(equalToConstant: 44),
            chatButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 이미지
            postImageView.topAnchor.constraint(equalTo: authorView.bottomAnchor),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postImageView.heightAnchor.constraint(equalToConstant: 250),
            
            // 제목
            titleLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 날짜/장소
            dateTimeLocationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dateTimeLocationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTimeLocationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 내용
            contentLabel.topAnchor.constraint(equalTo: dateTimeLocationLabel.bottomAnchor, constant: 16),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 비용
            costLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 16),
            costLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // 카테고리/태그
            categoryTagLabel.topAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 8),
            categoryTagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryTagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryTagLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // 하단 액션들
            favoriteButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 16),
            favoriteButton.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            favoriteCountLabel.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor),
            favoriteCountLabel.centerXAnchor.constraint(equalTo: favoriteButton.centerXAnchor),
            
            participateButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 16),
            participateButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16),
            participateButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            participateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        participateButton.addTarget(self, action: #selector(participateButtonTapped), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        // 본인 게시물인 경우에만 메뉴 버튼 추가
        if isCurrentUserAuthor {
            let menuButton = UIBarButtonItem(
                image: UIImage(systemName: "ellipsis"),
                style: .plain,
                target: self,
                action: #selector(menuButtonTapped)
            )
            navigationItem.rightBarButtonItem = menuButton
        }
    }
    
    private func configureWithPost() {
        titleLabel.text = post.title
        contentLabel.text = post.content
        
        // 날짜/시간/장소 정보
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM월 dd일 HH:mm"
        let dateTimeText = dateFormatter.string(from: post.meetingTime)
        dateTimeLocationLabel.text = "\(dateTimeText)\n\(post.address) \(post.detailAddress)"
        
        // 비용 정보
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let costText = numberFormatter.string(from: NSNumber(value: post.cost)) ?? "0"
        costLabel.text = "참여 금액  ₩\(costText)원"
        
        // 카테고리/지역
        categoryTagLabel.text = "\(post.category) • \(post.tag)"
        
        // 이미지 로딩
        loadImage(from: post.imageUrls.first ?? post.imageUrl)
        
        updateParticipateButton()
    }
    
    // MARK: - Data Loading
    private func loadPostDetails() {
        // Post 모델에서 직접 authorId 가져오기
        self.authorId = post.authorId
        
        // 현재 사용자가 작성자인지 확인
        if let currentUserId = Auth.auth().currentUser?.uid {
            self.isCurrentUserAuthor = (self.authorId == currentUserId)
            self.setupNavigationBar()
            
            // 본인 게시물이면 채팅 버튼 숨김
            self.chatButton.isHidden = self.isCurrentUserAuthor
        }
        
        // 작성자 정보 로드
        self.loadAuthorInfo()
    }
    
    private func loadAuthorInfo() {
        guard !authorId.isEmpty else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(authorId).getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists else {
                DispatchQueue.main.async {
                    self?.authorNameLabel.text = "작성자"
                }
                return
            }
            
            let data = document.data()
            let nickname = data?["user_nickname"] as? String ?? "작성자"
            let profileImageUrl = data?["profile_image"] as? String
            
            DispatchQueue.main.async {
                self.authorNameLabel.text = nickname
                
                // 프로필 이미지 로드
                if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
                    self.loadAuthorImage(from: profileImageUrl)
                }
            }
        }
    }
    
    private func loadAuthorImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.authorImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - 참가 버튼 업데이트 (기존 메서드 수정)
    private func updateParticipateButton() {
        if isCurrentUserAuthor {
            // 본인 게시물인 경우
            participateButton.setTitle("참여인원 확인 (\(participantsCount)/\(post.recruit))", for: .normal)
            participateButton.backgroundColor = .systemBlue
        } else {
            // 다른 사람 게시물인 경우
            let isRecruitmentFull = participantsCount >= post.recruit
            
            if isParticipating {
                // 이미 참가한 상태
                participateButton.setTitle("참가 취소 (\(participantsCount)/\(post.recruit))", for: .normal)
                participateButton.backgroundColor = .systemOrange
            } else if isRecruitmentFull {
                // 모집 마감
                participateButton.setTitle("모집 마감 (\(participantsCount)/\(post.recruit))", for: .normal)
                participateButton.backgroundColor = .systemGray
                participateButton.isEnabled = false
            } else {
                // 참가 가능
                participateButton.setTitle("참가하기 (\(participantsCount)/\(post.recruit))", for: .normal)
                participateButton.backgroundColor = .systemBlue
                participateButton.isEnabled = true
            }
        }
    }
    
    private func loadParticipantsData() {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("proposers").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.participantsCount = snapshot?.documents.count ?? 0
                self?.updateParticipateButton()
            }
        }
    }
    
    private func loadFavoriteData() {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("favorite").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.favoriteCount = snapshot?.documents.count ?? 0
                self?.favoriteCountLabel.text = "\(self?.favoriteCount ?? 0)"
            }
        }
    }
    
    private func checkUserFavoriteStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).collection("favorite").document(currentUserId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isFavorited = document?.exists ?? false
                self?.updateFavoriteButton()
            }
        }
    }
    
    private func updateFavoriteButton() {
        let imageName = isFavorited ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func loadImage(from urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            postImageView.image = UIImage(systemName: "photo.fill")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.postImageView.image = UIImage(systemName: "photo.fill")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.postImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showLoginAlert()
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
                    self?.favoriteCount = max(0, (self?.favoriteCount ?? 1) - 1)
                    self?.updateFavoriteButton()
                    self?.favoriteCountLabel.text = "\(self?.favoriteCount ?? 0)"
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
                    self?.favoriteCount = (self?.favoriteCount ?? 0) + 1
                    self?.updateFavoriteButton()
                    self?.favoriteCountLabel.text = "\(self?.favoriteCount ?? 0)"
                }
            }
        }
    }
    
    // MARK: - 참가 버튼 액션 (기존 메서드 수정)
    @objc private func participateButtonTapped() {
        if isCurrentUserAuthor {
            // 본인 게시물인 경우 참여인원 목록 표시
            showParticipantsList()
        } else {
            // 다른 사람 게시물인 경우 참가/취소 기능
            guard Auth.auth().currentUser != nil else {
                showLoginAlert()
                return
            }
            
            // 모집 마감인 경우 처리
            if participantsCount >= post.recruit && !isParticipating {
                showRecruitmentFullAlert()
                return
            }
            
            // 확인 알림 표시
            let actionTitle = isParticipating ? "참가를 취소하시겠습니까?" : "이 모임에 참가하시겠습니까?"
            let buttonTitle = isParticipating ? "취소" : "참가"
            
            let alert = UIAlertController(title: "참가 확인", message: actionTitle, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "아니오", style: .cancel))
            alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { [weak self] _ in
                self?.toggleParticipation()
            })
            
            present(alert, animated: true)
        }
    }
    
    @objc private func chatButtonTapped() {
        print("채팅 버튼 탭됨")
        // TODO: 채팅 기능 구현
    }
    
    @objc private func menuButtonTapped() {
        let alert = UIAlertController(title: "게시물 관리", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "수정", style: .default) { [weak self] _ in
            self?.editPost()
        })
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func editPost() {
        let createPostVC = CreatePostViewController()
        createPostVC.setEditMode(with: post) // 수정 모드로 설정
        let navController = UINavigationController(rootViewController: createPostVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "게시물 삭제",
            message: "정말로 이 게시물을 삭제하시겠습니까?\n삭제된 게시물은 복구할 수 없습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deletePost()
        })
        
        present(alert, animated: true)
    }
    
    private func deletePost() {
        let db = Firestore.firestore()
        
        // 간단한 로딩 메시지 표시
        let loadingAlert = UIAlertController(title: "삭제 중...", message: "잠시만 기다려주세요.", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // 게시물 삭제
        db.collection("posts").document(post.id).delete { [weak self] error in
            DispatchQueue.main.async {
                // 로딩 알림 닫기
                loadingAlert.dismiss(animated: true) {
                    if let error = error {
                        self?.showErrorAlert(message: "게시물 삭제에 실패했습니다: \(error.localizedDescription)")
                        return
                    }
                    
                    // 삭제 성공
                    self?.showSuccessAlert(message: "게시물이 삭제되었습니다.") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    private func showParticipantsList() {
        let participantsListVC = ParticipantsListViewController(postId: post.id, participantsCount: participantsCount)
        let navController = UINavigationController(rootViewController: participantsListVC)
        present(navController, animated: true)
    }
    
    
    private func showLoginAlert() {
        let alert = UIAlertController(
            title: "로그인 필요",
            message: "이 기능을 사용하려면 로그인이 필요합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "완료", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
    
    // MARK: - 참가 상태 확인
        private func checkUserParticipationStatus() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            db.collection("posts").document(post.id).collection("proposers").document(currentUserId).getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    self?.isParticipating = document?.exists ?? false
                    self?.updateParticipateButton()
                }
            }
        }
    
    // MARK: - 참가/취소 토글
    private func toggleParticipation() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showLoginAlert()
            return
        }
        
        let db = Firestore.firestore()
        let proposerRef = db.collection("posts").document(post.id).collection("proposers").document(currentUserId)
        
        if isParticipating {
            // 참가 취소
            proposerRef.delete { [weak self] error in
                if let error = error {
                    print("참가 취소 실패: \(error)")
                    DispatchQueue.main.async {
                        self?.showErrorAlert(message: "참가 취소에 실패했습니다.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.isParticipating = false
                    self?.participantsCount = max(0, (self?.participantsCount ?? 1) - 1)
                    self?.updateParticipateButton()
                    print("✅ 참가 취소 완료")
                }
            }
        } else {
            // 참가 신청
            // 먼저 현재 참가 인원 확인
            if participantsCount >= post.recruit {
                showRecruitmentFullAlert()
                return
            }
            
            let participationData: [String: Any] = [
                "user_id": currentUserId,
                "createdAt": Timestamp(date: Date())
            ]
            
            proposerRef.setData(participationData) { [weak self] error in
                if let error = error {
                    print("참가 신청 실패: \(error)")
                    DispatchQueue.main.async {
                        self?.showErrorAlert(message: "참가 신청에 실패했습니다.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.isParticipating = true
                    self?.participantsCount = (self?.participantsCount ?? 0) + 1
                    self?.updateParticipateButton()
                    print("✅ 참가 신청 완료")
                }
            }
        }
    }
    
    
    // MARK: - 모집 인원 초과 알림
    private func showRecruitmentFullAlert() {
        let alert = UIAlertController(
            title: "모집 마감",
            message: "모집 인원이 모두 모집되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
}
