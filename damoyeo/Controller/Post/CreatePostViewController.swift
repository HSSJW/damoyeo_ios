//
//  CreatePostViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import WebKit

// MARK: - 필요한 구조체들 (파일 상단에 정의)
struct GeneratedPostData {
    let title: String
    let content: String
    let category: String
    let region: String
    let address: String
    let detailAddress: String
    let recruit: Int
    let cost: Int
    let meetingTime: Date
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case invalidJSON
    case jsonParseError
    case missingRequiredFields
    case invalidDateFormat
    case invalidRecruitNumber
    case invalidCost
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .httpError(let code):
            return "HTTP 오류: \(code)"
        case .noData:
            return "데이터를 받지 못했습니다."
        case .invalidJSON:
            return "JSON 형식이 올바르지 않습니다."
        case .jsonParseError:
            return "JSON 파싱에 실패했습니다."
        case .missingRequiredFields:
            return "필수 정보가 누락되었습니다."
        case .invalidDateFormat:
            return "날짜 형식이 올바르지 않습니다."
        case .invalidRecruitNumber:
            return "모집인원은 2-20명 사이여야 합니다."
        case .invalidCost:
            return "비용은 0-100,000원 사이여야 합니다."
        }
    }
}

class CreatePostViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 수정관련 코드
    private var isEditMode = false
    private var editingPost: Post?
    
    // AI 생성 버튼
    private let aiGenerateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✨ AI로 게시물 생성하기", for: .normal)
        button.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        button.setTitleColor(.systemPurple, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemPurple.cgColor
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        // 아이콘 추가
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let icon = UIImage(systemName: "wand.and.stars", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        
        return button
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "제목을 입력하세요"
        return textField
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("카테고리 선택", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()
    
    private let regionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("지역 선택", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()
    
    private let addressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "기본 주소"
        textField.isUserInteractionEnabled = false
        return textField
    }()
    
    private let addressButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("주소 찾기", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let detailAddressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "상세 주소"
        return textField
    }()
    
    private let dateTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("날짜와 시간 선택", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()
    
    private let recruitTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "모집 인원"
        textField.keyboardType = .numberPad
        return textField
    }()
    
    private let costTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "예상 활동 금액 (원)"
        textField.keyboardType = .numberPad
        return textField
    }()
    
    private let contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = "모집글 내용을 작성해주세요."
        textView.textColor = .placeholderText
        return textView
    }()
    
    private let imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("작성 완료", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    // MARK: - Properties
    private var selectedCategory: String?
    private var selectedRegion: String?
    private var selectedDateTime: Date?
    private var selectedImages: [UIImage] = []
    
    private let categories = ["친목", "스포츠", "스터디", "여행", "알바", "게임", "봉사", "헬스", "음악", "기타"]
    private let regions = [
        "서울특별시", "부산광역시", "대구광역시", "인천광역시",
        "광주광역시", "대전광역시", "울산광역시", "세종특별자치시",
        "경기도", "강원도", "충청북도", "충청남도",
        "전라북도", "전라남도", "경상북도", "경상남도", "제주특별자치도"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupActions()
        setupImageCollection()
        setupAIFeature() // AI 기능 설정 추가
        
        // 수정 모드인 경우 기존 데이터 로드
        if isEditMode, let post = editingPost {
            loadPostData(post)
        }
    }
    
    // 수정모드
    func setEditMode(with post: Post) {
        isEditMode = true
        editingPost = post
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = isEditMode ? "모집글 수정" : "모집글 작성"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // AI 버튼을 맨 처음에 추가
        [aiGenerateButton, titleTextField, categoryButton, regionButton, addressTextField, addressButton,
         detailAddressTextField, dateTimeButton, recruitTextField, costTextField,
         contentTextView, imageCollectionView, submitButton].forEach {
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    // MARK: - AI 기능 설정
    private func setupAIFeature() {
        // 수정 모드일 때는 AI 버튼 숨기기
        aiGenerateButton.isHidden = isEditMode
        
        aiGenerateButton.addTarget(self, action: #selector(aiGenerateButtonTapped), for: .touchUpInside)
    }
    
    @objc private func aiGenerateButtonTapped() {
        let aiGeneratorVC = AIPostGeneratorViewController()
        
        // AI 생성 완료 콜백 설정
        aiGeneratorVC.onPostGenerated = { [weak self] (generatedData: GeneratedPostData) in
            self?.fillFormWithGeneratedData(generatedData)
        }
        
        let navController = UINavigationController(rootViewController: aiGeneratorVC)
        navController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        
        // iOS 15+ 에서 시트 높이 조절
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(navController, animated: true)
    }
    
    // MARK: - AI 생성 데이터로 폼 채우기
    func fillFormWithGeneratedData(_ data: GeneratedPostData) {
        print("🎯 AI 생성 데이터로 폼 채우기 시작")
        
        // 애니메이션으로 부드럽게 채우기
        UIView.animate(withDuration: 0.3) {
            // 제목 설정
            self.titleTextField.text = data.title
            
            // 내용 설정
            self.contentTextView.text = data.content
            self.contentTextView.textColor = .label
            
            // 카테고리 설정
            self.selectedCategory = data.category
            self.categoryButton.setTitle(data.category, for: .normal)
            
            // 지역 설정
            self.selectedRegion = data.region
            self.regionButton.setTitle(data.region, for: .normal)
            
            // 주소 설정
            self.addressTextField.text = data.address
            self.detailAddressTextField.text = data.detailAddress
            
            // 모집인원 설정
            self.recruitTextField.text = "\(data.recruit)"
            
            // 비용 설정
            self.costTextField.text = "\(data.cost)"
        }
        
        // 날짜시간 설정 (애니메이션 후)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedDateTime = data.meetingTime
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일 HH:mm"
            self.dateTimeButton.setTitle(formatter.string(from: data.meetingTime), for: .normal)
            
            // 성공 알림 표시
            self.showGenerationSuccessAlert()
            
            // 스크롤을 맨 위로 이동
            self.scrollView.setContentOffset(.zero, animated: true)
        }
        
        print("✅ AI 생성 데이터로 폼 채우기 완료")
    }
    
    private func showGenerationSuccessAlert() {
        let alert = UIAlertController(
            title: "AI 생성 완료! ✨",
            message: "게시물이 자동으로 생성되었습니다. 내용을 확인하고 필요시 수정해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - 기존 게시물 데이터 로드
    private func loadPostData(_ post: Post) {
        titleTextField.text = post.title
        contentTextView.text = post.content
        contentTextView.textColor = .label
        
        // 카테고리 설정
        selectedCategory = post.category
        categoryButton.setTitle(post.category, for: .normal)
        
        // 지역 설정
        selectedRegion = post.tag
        regionButton.setTitle(post.tag, for: .normal)
        
        // 주소 설정
        addressTextField.text = post.address
        detailAddressTextField.text = post.detailAddress
        
        // 날짜시간 설정
        selectedDateTime = post.meetingTime
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일 HH:mm"
        dateTimeButton.setTitle(formatter.string(from: post.meetingTime), for: .normal)
        
        // 모집인원 설정
        recruitTextField.text = "\(post.recruit)"
        
        // 비용 설정
        costTextField.text = "\(post.cost)"
        
        // 기존 이미지 URL들을 UIImage로 변환해서 로드
        loadExistingImages(from: post.imageUrls)
    }

    // MARK: - 기존 이미지 로드
    private func loadExistingImages(from urls: [String]) {
        let group = DispatchGroup()
        var loadedImages: [UIImage] = []
        
        for url in urls.prefix(10) { // 최대 10개만
            group.enter()
            
            guard let imageUrl = URL(string: url) else {
                group.leave()
                continue
            }
            
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                defer { group.leave() }
                
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }
                
                loadedImages.append(image)
            }.resume()
        }
        
        group.notify(queue: .main) {
            self.selectedImages = loadedImages
            self.imageCollectionView.reloadData()
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupConstraints() {
        [scrollView, contentView, aiGenerateButton, titleTextField, categoryButton, regionButton,
         addressTextField, addressButton, detailAddressTextField, dateTimeButton,
         recruitTextField, costTextField, contentTextView, imageCollectionView,
         submitButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // AI Generate Button (맨 위)
            aiGenerateButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            aiGenerateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aiGenerateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            aiGenerateButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Title (AI 버튼 아래)
            titleTextField.topAnchor.constraint(equalTo: aiGenerateButton.bottomAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Category
            categoryButton.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Region
            regionButton.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 16),
            regionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            regionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            regionButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Address Row
            addressTextField.topAnchor.constraint(equalTo: regionButton.bottomAnchor, constant: 16),
            addressTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addressTextField.trailingAnchor.constraint(equalTo: addressButton.leadingAnchor, constant: -8),
            addressTextField.heightAnchor.constraint(equalToConstant: 50),
            
            addressButton.topAnchor.constraint(equalTo: addressTextField.topAnchor),
            addressButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addressButton.widthAnchor.constraint(equalToConstant: 80),
            addressButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Detail Address
            detailAddressTextField.topAnchor.constraint(equalTo: addressTextField.bottomAnchor, constant: 8),
            detailAddressTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailAddressTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailAddressTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // DateTime
            dateTimeButton.topAnchor.constraint(equalTo: detailAddressTextField.bottomAnchor, constant: 16),
            dateTimeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTimeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateTimeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Recruit
            recruitTextField.topAnchor.constraint(equalTo: dateTimeButton.bottomAnchor, constant: 16),
            recruitTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recruitTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recruitTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Cost
            costTextField.topAnchor.constraint(equalTo: recruitTextField.bottomAnchor, constant: 16),
            costTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            costTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            costTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Image Collection
            imageCollectionView.topAnchor.constraint(equalTo: costTextField.bottomAnchor, constant: 16),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageCollectionView.heightAnchor.constraint(equalToConstant: 70),
            
            // Content
            contentTextView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // Submit Button
            submitButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupActions() {
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        regionButton.addTarget(self, action: #selector(regionButtonTapped), for: .touchUpInside)
        addressButton.addTarget(self, action: #selector(addressButtonTapped), for: .touchUpInside)
        dateTimeButton.addTarget(self, action: #selector(dateTimeButtonTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        // 버튼 타이틀 변경
        submitButton.setTitle(isEditMode ? "수정 완료" : "작성 완료", for: .normal)
        
        contentTextView.delegate = self
    }
    
    private func setupImageCollection() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        imageCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        imageCollectionView.register(AddImageCell.self, forCellWithReuseIdentifier: "AddImageCell")
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func categoryButtonTapped() {
        showSelectionAlert(title: "카테고리 선택", options: categories) { [weak self] selected in
            self?.selectedCategory = selected
            self?.categoryButton.setTitle(selected, for: .normal)
        }
    }
    
    @objc private func regionButtonTapped() {
        showSelectionAlert(title: "지역 선택", options: regions) { [weak self] selected in
            self?.selectedRegion = selected
            self?.regionButton.setTitle(selected, for: .normal)
        }
    }
    
    @objc private func addressButtonTapped() {
        showDaumAddressSearch()
    }

    private func showDaumAddressSearch() {
        print("주소 검색 시작")
        let addressSearchVC = DaumAddressSearchViewController()
        
        addressSearchVC.onAddressSelected = { [weak self] address in
            DispatchQueue.main.async {
                self?.addressTextField.text = address
            }
        }
        
        let navController = UINavigationController(rootViewController: addressSearchVC)
        navController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        present(navController, animated: true)
    }
    
    @objc private func dateTimeButtonTapped() {
        showDateTimeSelection()
    }

    private func showDateTimeSelection() {
        let dateTimeVC = DateTimeSelectionViewController()
        dateTimeVC.minimumDate = Date()
        
        // 현재 선택된 날짜시간이 있다면 설정
        if let selectedDateTime = selectedDateTime {
            dateTimeVC.selectedDateTime = selectedDateTime
        }
        
        // 클로저 타입 명시
        dateTimeVC.onDateTimeSelected = { [weak self] (dateTime: Date) in
            self?.selectedDateTime = dateTime
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일 HH:mm"
            self?.dateTimeButton.setTitle(formatter.string(from: dateTime), for: .normal)
        }
        
        let navController = UINavigationController(rootViewController: dateTimeVC)
        navController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        present(navController, animated: true)
    }
    
    @objc private func submitButtonTapped() {
        guard validateInput() else { return }
        
        submitButton.isEnabled = false
        submitButton.setTitle(isEditMode ? "수정 중..." : "업로드 중...", for: .normal)
        
        if isEditMode {
            updatePost()
        } else {
            uploadPost()
        }
    }
    
    // MARK: - 게시물 수정
    private func updatePost() {
        guard let post = editingPost else {
            resetSubmitButton()
            return
        }
        
        // 이미지 업로드 후 게시물 데이터 업데이트
        uploadImages { [weak self] imageUrls in
            guard let self = self else { return }
            
            let updatedData: [String: Any] = [
                "title": self.titleTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "content": self.contentTextView.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "tag": self.selectedRegion!,
                "category": self.selectedCategory!,
                "address": self.addressTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "detailAddress": self.detailAddressTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "recruit": Int(self.recruitTextField.text!)!,
                "cost": Int(self.costTextField.text!)!,
                "meetingTime": Timestamp(date: self.selectedDateTime!),
                "imageUrl": imageUrls.first ?? "",
                "imageUrls": imageUrls
            ]
            
            let db = Firestore.firestore()
            db.collection("posts").document(post.id).updateData(updatedData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showAlert(message: "게시물 수정 실패: \(error.localizedDescription)")
                        self.resetSubmitButton()
                        return
                    }
                    
                    self.showUpdateSuccessAlert()
                }
            }
        }
    }
    
    private func showSelectionAlert(title: String, options: [String], completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for option in options {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                completion(option)
            })
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    private func validateInput() -> Bool {
        // 제목 검증
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            showAlert(message: "제목을 입력해주세요.")
            return false
        }
        
        // 카테고리 검증
        guard selectedCategory != nil else {
            showAlert(message: "카테고리를 선택해주세요.")
            return false
        }
        
        // 지역 검증
        guard selectedRegion != nil else {
            showAlert(message: "지역을 선택해주세요.")
            return false
        }
        
        // 주소 검증
        guard let address = addressTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            showAlert(message: "주소를 입력해주세요.")
            return false
        }
        
        // 상세주소 검증
        guard let detailAddress = detailAddressTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !detailAddress.isEmpty else {
            showAlert(message: "상세주소를 입력해주세요.")
            return false
        }
        
        // 모집인원 검증
        guard let recruitText = recruitTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !recruitText.isEmpty,
              let recruit = Int(recruitText),
              recruit > 0 else {
            showAlert(message: "올바른 모집인원을 입력해주세요.")
            return false
        }
        
        // 비용 검증
        guard let costText = costTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !costText.isEmpty,
              let cost = Int(costText),
              cost >= 0 else {
            showAlert(message: "올바른 활동 금액을 입력해주세요.")
            return false
        }
        
        // 내용 검증
        guard let content = contentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              content != "모집글 내용을 작성해주세요.",
              !content.isEmpty else {
            showAlert(message: "모집글 내용을 작성해주세요.")
            return false
        }
        
        // 날짜 검증
        guard selectedDateTime != nil else {
            showAlert(message: "모임 날짜와 시간을 선택해주세요.")
            return false
        }
        
        return true
    }
    
    private func uploadPost() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(message: "로그인이 필요합니다.")
            resetSubmitButton()
            return
        }
        
        // 이미지 업로드 후 게시물 데이터 저장
        uploadImages { [weak self] imageUrls in
            guard let self = self else { return }
            
            let postData: [String: Any] = [
                "id": userId,
                "title": self.titleTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "content": self.contentTextView.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "tag": self.selectedRegion!,
                "category": self.selectedCategory!,
                "address": self.addressTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "detailAddress": self.detailAddressTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
                "recruit": Int(self.recruitTextField.text!)!,
                "cost": Int(self.costTextField.text!)!,
                "meetingTime": Timestamp(date: self.selectedDateTime!),
                "createdAt": Timestamp(date: Date()),
                "imageUrl": imageUrls.first ?? "",
                "imageUrls": imageUrls
            ]
            
            let db = Firestore.firestore()
            
            // 1. 게시물 문서 참조 생성 (ID 미리 생성)
            let postRef = db.collection("posts").document()
            let postId = postRef.documentID
            
            // 2. 게시물 생성
            postRef.setData(postData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(message: "게시물 작성 실패: \(error.localizedDescription)")
                        self.resetSubmitButton()
                    }
                    return
                }
                
                // 3. 작성자를 참가자로 자동 추가
                let proposerData: [String: Any] = [
                    "user_id": userId,
                    "createdAt": Timestamp(date: Date())
                ]
                
                postRef.collection("proposers").document(userId).setData(proposerData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("참가자 자동 등록 실패: \(error)")
                            // 게시물은 생성되었으니 성공으로 처리
                        } else {
                            print("✅ 작성자가 참가자로 자동 등록되었습니다")
                        }
                        
                        self.showSuccessAlert()
                    }
                }
            }
        }
    }
    
    private func resetSubmitButton() {
        submitButton.isEnabled = true
        submitButton.setTitle(isEditMode ? "수정 완료" : "작성 완료", for: .normal)
    }

    private func showUpdateSuccessAlert() {
        let alert = UIAlertController(title: "완료", message: "게시물이 성공적으로 수정되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "완료", message: "게시물이 성공적으로 작성되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func uploadImages(completion: @escaping ([String]) -> Void) {
        guard !selectedImages.isEmpty else {
            completion([])
            return
        }
        
        var uploadedUrls: [String] = []
        let group = DispatchGroup()
        
        for (index, image) in selectedImages.enumerated() {
            group.enter()
            
            let storageRef = Storage.storage().reference().child("post_images/\(UUID().uuidString).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                group.leave()
                continue
            }
            
            storageRef.putData(imageData) { _, error in
                if error == nil {
                    storageRef.downloadURL { url, _ in
                        if let urlString = url?.absoluteString {
                            uploadedUrls.append(urlString)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedUrls)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showImagePicker() {
        // iOS 14+ PHPickerViewController 사용
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 10 - selectedImages.count // 남은 개수만큼만 선택 가능
            configuration.filter = .images
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            // iOS 13 이하에서는 UIImagePickerController 사용
            showLegacyImagePicker()
        }
    }
    
    private func showLegacyImagePicker() {
        let alert = UIAlertController(title: "이미지 선택", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "카메라", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            })
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "갤러리", style: .default) { _ in
                self.presentImagePicker(sourceType: .photoLibrary)
            })
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "모집글 내용을 작성해주세요."
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension CreatePostViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count + (selectedImages.count < 10 ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < selectedImages.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
            cell.configure(with: selectedImages[indexPath.row])
            cell.onDelete = { [weak self] in
                self?.selectedImages.remove(at: indexPath.row)
                self?.imageCollectionView.reloadData()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddImageCell", for: indexPath) as! AddImageCell
            cell.onTap = { [weak self] in
                self?.showImagePicker()
            }
            return cell
        }
    }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)
@available(iOS 14, *)
extension CreatePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        self?.selectedImages.append(image)
                        self?.imageCollectionView.reloadData()
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (iOS 13 이하 호환)
extension CreatePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            selectedImages.append(image)
            imageCollectionView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Custom Cells
class ImageCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let deleteButton = UIButton()
    var onDelete: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 10
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        addSubview(imageView)
        addSubview(deleteButton)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: -5),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}

class AddImageCell: UICollectionViewCell {
    private let addButton = UIButton()
    var onTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.backgroundColor = .systemGray6
        addButton.layer.cornerRadius = 8
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor.systemGray4.cgColor
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: topAnchor),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc private func addButtonTapped() {
        onTap?()
    }
}

// MARK: - DateTimeSelectionViewController (날짜+시간 통합 선택)
class DateTimeSelectionViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 날짜 선택 부분
    private let monthLabel = UILabel()
    private let prevButton = UIButton()
    private let nextButton = UIButton()
    private let weekdayStackView = UIStackView()
    private let daysCollectionView: UICollectionView
    
    // 시간 선택 부분
    private let timeLabel = UILabel()
    private let timePicker = UIDatePicker()
    
    var selectedDateTime: Date = Date()
    var minimumDate: Date?
    var onDateTimeSelected: ((Date) -> Void)?
    
    private var displayedMonth = Date()
    private var selectedDate = Date()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        daysCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updateCalendar()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "날짜와 시간 선택"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupMonthHeader()
        setupWeekdayHeader()
        setupDaysCollectionView()
        setupTimePicker()
        setupConstraints()
        
        // 초기값 설정
        selectedDate = selectedDateTime
        displayedMonth = selectedDateTime
        timePicker.date = selectedDateTime
        updateMonthLabel()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    private func setupMonthHeader() {
        monthLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        monthLabel.textAlignment = .center
        
        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        prevButton.setTitleColor(.systemBlue, for: .normal)
        prevButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        nextButton.setTitleColor(.systemBlue, for: .normal)
        nextButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
        
        contentView.addSubview(monthLabel)
        contentView.addSubview(prevButton)
        contentView.addSubview(nextButton)
    }
    
    private func setupWeekdayHeader() {
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        weekdayStackView.axis = .horizontal
        weekdayStackView.distribution = .fillEqually
        
        for weekday in weekdays {
            let label = UILabel()
            label.text = weekday
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = .systemGray
            weekdayStackView.addArrangedSubview(label)
        }
        
        contentView.addSubview(weekdayStackView)
    }
    
    private func setupDaysCollectionView() {
        daysCollectionView.backgroundColor = .clear
        daysCollectionView.delegate = self
        daysCollectionView.dataSource = self
        daysCollectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "DayCell")
        daysCollectionView.isScrollEnabled = false
        
        contentView.addSubview(daysCollectionView)
    }
    
    private func setupTimePicker() {
        timeLabel.text = "시간 선택"
        timeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        timeLabel.textAlignment = .center
        
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(timePicker)
    }
    
    private func setupConstraints() {
        [scrollView, contentView, monthLabel, prevButton, nextButton,
         weekdayStackView, daysCollectionView, timeLabel, timePicker].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Month Header
            prevButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            prevButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            prevButton.heightAnchor.constraint(equalToConstant: 44),
            
            monthLabel.centerYAnchor.constraint(equalTo: prevButton.centerYAnchor),
            monthLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nextButton.centerYAnchor.constraint(equalTo: prevButton.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Weekday Header
            weekdayStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 20),
            weekdayStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weekdayStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weekdayStackView.heightAnchor.constraint(equalToConstant: 30),
            
            // Days Collection View
            daysCollectionView.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor, constant: 10),
            daysCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            daysCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            daysCollectionView.heightAnchor.constraint(equalToConstant: 240),
            
            // Time Section
            timeLabel.topAnchor.constraint(equalTo: daysCollectionView.bottomAnchor, constant: 30),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            timePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            timePicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timePicker.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func updateCalendar() {
        updateMonthLabel()
        daysCollectionView.reloadData()
    }
    
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        monthLabel.text = formatter.string(from: displayedMonth)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        // 선택된 날짜와 시간을 합침
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        if let combinedDateTime = calendar.date(from: combinedComponents) {
            onDateTimeSelected?(combinedDateTime)
        }
        
        dismiss(animated: true)
    }
    
    @objc private func prevMonthTapped() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        updateCalendar()
    }
    
    @objc private func nextMonthTapped() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        updateCalendar()
    }
}

// MARK: - UICollectionView Methods
extension DateTimeSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! CalendarDayCell
        
        let calendar = Calendar.current
        let firstDayOfMonth = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        let dayOffset = indexPath.row - firstWeekday
        
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
            let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            let isToday = calendar.isDateInToday(date)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let isPastDate = date < Date() && !calendar.isDateInToday(date)
            
            cell.configure(
                day: calendar.component(.day, from: date),
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                isPastDate: isPastDate
            )
            
            cell.date = date
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CalendarDayCell,
              let date = cell.date else { return }
        
        // 과거 날짜 선택 방지
        if date < Date() && !Calendar.current.isDateInToday(date) {
            return
        }
        
        selectedDate = date
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 6) / 7
        return CGSize(width: width, height: 40)
    }
}

// MARK: - CalendarDayCell
class CalendarDayCell: UICollectionViewCell {
    
    private let dayLabel = UILabel()
    var date: Date?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dayLabel.textAlignment = .center
        dayLabel.font = .systemFont(ofSize: 16)
        
        contentView.addSubview(dayLabel)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        contentView.layer.cornerRadius = 8
    }
    
    func configure(day: Int, isCurrentMonth: Bool, isToday: Bool, isSelected: Bool, isPastDate: Bool) {
        dayLabel.text = "\(day)"
        
        // 색상 및 스타일 설정
        if isPastDate {
            dayLabel.textColor = .systemGray4
            contentView.backgroundColor = .clear
        } else if isSelected {
            dayLabel.textColor = .white
            contentView.backgroundColor = .systemBlue
        } else if isToday {
            dayLabel.textColor = .systemBlue
            contentView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        } else if isCurrentMonth {
            dayLabel.textColor = .label
            contentView.backgroundColor = .clear
        } else {
            dayLabel.textColor = .systemGray3
            contentView.backgroundColor = .clear
        }
    }
}
