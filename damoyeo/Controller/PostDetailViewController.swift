//
//  PostDetailViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseFirestore

class PostDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let post: Post
    private var participantsCount = 0
    private var isFavorited = false
    private var favoriteCount = 0
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithPost()
        loadParticipantsData()
        loadFavoriteData()
        setupNavigationBar()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
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
        // TODO: 본인 게시물인 경우 수정/삭제 버튼 추가
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
        
        // 작성자 정보 (임시)
        authorNameLabel.text = "작성자" // TODO: 실제 작성자 정보 로드
        
        // 이미지 로딩
        loadImage(from: post.imageUrls.first ?? post.imageUrl)
        
        updateParticipateButton()
    }
    
    private func updateParticipateButton() {
        participateButton.setTitle("참여하기 (\(participantsCount)/\(post.recruit))", for: .normal)
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
        print("좋아요 버튼 탭됨")
        // TODO: 좋아요 기능 구현
    }
    
    @objc private func participateButtonTapped() {
        print("참여하기 버튼 탭됨")
        // TODO: 참여 기능 구현
    }
    
    @objc private func chatButtonTapped() {
        print("채팅 버튼 탭됨")
        // TODO: 채팅 기능 구현
    }
}
