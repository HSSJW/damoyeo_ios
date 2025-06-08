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

class CreatePostViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "모집글 작성"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleTextField, categoryButton, regionButton, addressTextField, addressButton,
         detailAddressTextField, dateTimeButton, recruitTextField, costTextField,
         contentTextView, imageCollectionView, submitButton].forEach {
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupConstraints() {
        [scrollView, contentView, titleTextField, categoryButton, regionButton,
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
            
            // Title
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
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
        // TODO: 주소 검색 API 연동 (Daum 우편번호 서비스 등)
        addressTextField.text = "서울특별시 강남구 테헤란로 123"
    }
    
    @objc private func dateTimeButtonTapped() {
        let alert = UIAlertController(title: "날짜와 시간 선택", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        
        alert.setValue(datePicker, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.selectedDateTime = datePicker.date
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일 HH:mm"
            self?.dateTimeButton.setTitle(formatter.string(from: datePicker.date), for: .normal)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func submitButtonTapped() {
        guard validateInput() else { return }
        
        submitButton.isEnabled = false
        submitButton.setTitle("업로드 중...", for: .normal)
        
        uploadPost()
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
        guard let title = titleTextField.text, !title.isEmpty,
              let category = selectedCategory,
              let region = selectedRegion,
              let address = addressTextField.text, !address.isEmpty,
              let detailAddress = detailAddressTextField.text, !detailAddress.isEmpty,
              let recruitText = recruitTextField.text, !recruitText.isEmpty,
              let recruit = Int(recruitText),
              let costText = costTextField.text, !costText.isEmpty,
              let cost = Int(costText),
              let content = contentTextView.text, content != "모집글 내용을 작성해주세요.", !content.isEmpty,
              let dateTime = selectedDateTime else {
            
            showAlert(message: "모든 필드를 입력해주세요.")
            return false
        }
        
        return true
    }
    
    private func uploadPost() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 이미지 업로드 (간단 구현)
        uploadImages { [weak self] imageUrls in
            guard let self = self else { return }
            
            let postData: [String: Any] = [
                "id": userId,
                "title": self.titleTextField.text!,
                "content": self.contentTextView.text!,
                "tag": self.selectedRegion!,
                "category": self.selectedCategory!,
                "address": self.addressTextField.text!,
                "detailAddress": self.detailAddressTextField.text!,
                "recruit": Int(self.recruitTextField.text!)!,
                "cost": Int(self.costTextField.text!)!,
                "meetingTime": Timestamp(date: self.selectedDateTime!),
                "createdAt": Timestamp(date: Date()),
                "imageUrl": imageUrls.first ?? "",
                "imageUrls": imageUrls
            ]
            
            let db = Firestore.firestore()
            db.collection("posts").addDocument(data: postData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showAlert(message: "게시물 작성 실패: \(error.localizedDescription)")
                        self.submitButton.isEnabled = true
                        self.submitButton.setTitle("작성 완료", for: .normal)
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func uploadImages(completion: @escaping ([String]) -> Void) {
        guard !selectedImages.isEmpty else {
            completion([])
            return
        }
        
        // Firebase Storage에 이미지 업로드 (간단 구현)
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
    
    private func showImagePicker() {
        let alert = UIAlertController(title: "이미지 선택", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "카메라", style: .default) { _ in
            // TODO: 카메라 연동
        })
        
        alert.addAction(UIAlertAction(title: "갤러리", style: .default) { _ in
            // TODO: 갤러리 연동
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
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
