import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

class EditProfileViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 60
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let changePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사진 변경", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        return button
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "이름"
        return textField
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "닉네임"
        return textField
    }()
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "전화번호"
        textField.keyboardType = .phonePad
        return textField
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "이메일"
        textField.isEnabled = false
        textField.backgroundColor = .systemGray6
        return textField
    }()
    
    // MARK: - Properties
    private var userInfo: [String: Any]
    private var selectedImage: UIImage?
    private var hasImageChanged: Bool = false
    
    // MARK: - Initialization
    init(userInfo: [String: Any]) {
        self.userInfo = userInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupActions()
        loadUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "내 정보 수정"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(changePhotoButton)
        contentView.addSubview(nameTextField)
        contentView.addSubview(nicknameTextField)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(emailTextField)
        
        setupConstraints()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupActions() {
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        
        // 프로필 이미지 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped))
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        [scrollView, contentView, profileImageView, changePhotoButton,
         nameTextField, nicknameTextField, phoneTextField, emailTextField].forEach {
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
            
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Change Photo Button
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            changePhotoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Name TextField
            nameTextField.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 32),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Nickname TextField
            nicknameTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            nicknameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nicknameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Phone TextField
            phoneTextField.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 16),
            phoneTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Email TextField
            emailTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 16),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            emailTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func loadUserData() {
        // 사용자 정보 로드
        nameTextField.text = userInfo["user_name"] as? String
        nicknameTextField.text = userInfo["user_nickname"] as? String
        phoneTextField.text = userInfo["user_phoneNum"] as? String
        emailTextField.text = userInfo["user_email"] as? String ?? Auth.auth().currentUser?.email
        
        // 프로필 이미지 로드
        if let profileImageUrl = userInfo["profile_image"] as? String,
           !profileImageUrl.isEmpty,
           let url = URL(string: profileImageUrl) {
            loadProfileImage(from: url)
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // MARK: - Photo Selection
    @objc private func changePhotoTapped() {
        let alert = UIAlertController(title: "프로필 사진 변경", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "사진 라이브러리", style: .default) { _ in
            self.openPhotoLibrary()
        })
        
        alert.addAction(UIAlertAction(title: "카메라", style: .default) { _ in
            self.openCamera()
        })
        
        alert.addAction(UIAlertAction(title: "기본 이미지로 변경", style: .default) { _ in
            self.setDefaultImage()
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = changePhotoButton
            popover.sourceRect = changePhotoButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func openPhotoLibrary() {
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            present(picker, animated: true)
        }
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "카메라를 사용할 수 없습니다.")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func setDefaultImage() {
        selectedImage = nil
        hasImageChanged = true
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemGray3
        
        // 버튼 텍스트 변경으로 변경사항 표시
        changePhotoButton.setTitle("사진 변경됨", for: .normal)
        changePhotoButton.setTitleColor(.systemOrange, for: .normal)
    }
    
    // MARK: - Image Upload
    private func uploadProfileImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7),
              let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        profileImageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("이미지 업로드 실패: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("URL 가져오기 실패: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    private func removeProfileImageFromStorage(completion: @escaping () -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        profileImageRef.delete { error in
            if let error = error {
                print("이미지 삭제 실패: \(error.localizedDescription)")
            }
            completion()
        }
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 저장 버튼 비활성화
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.title = "저장 중..."
        
        var updatedData: [String: Any] = [
            "user_name": nameTextField.text ?? "",
            "user_nickname": nicknameTextField.text ?? "",
            "user_phoneNum": phoneTextField.text ?? ""
        ]
        
        // 이미지 변경이 있는 경우 처리
        if hasImageChanged {
            if let selectedImage = selectedImage {
                // 새 이미지 업로드
                uploadProfileImage(selectedImage) { [weak self] imageUrl in
                    DispatchQueue.main.async {
                        if let imageUrl = imageUrl {
                            updatedData["profile_image"] = imageUrl
                        }
                        self?.saveUserData(updatedData)
                    }
                }
                return
            } else {
                // 기본 이미지로 변경 (프로필 이미지 삭제)
                removeProfileImageFromStorage { [weak self] in
                    DispatchQueue.main.async {
                        updatedData["profile_image"] = ""
                        self?.saveUserData(updatedData)
                    }
                }
                return
            }
        }
        
        // 이미지 변경이 없는 경우
        saveUserData(updatedData)
    }
    
    private func saveUserData(_ data: [String: Any]) {
        guard let userId = Auth.auth().currentUser?.uid else {
            // 버튼 복원
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.title = nil
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            DispatchQueue.main.async {
                // 버튼 복원
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                self?.navigationItem.rightBarButtonItem?.title = nil
                
                if let error = error {
                    self?.showAlert(message: "저장 실패: \(error.localizedDescription)")
                } else {
                    self?.showAlert(message: "정보가 수정되었습니다.") {
                        self?.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)
@available(iOS 14, *)
extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.selectedImage = image
                    self?.hasImageChanged = true
                    self?.profileImageView.image = image
                    
                    // 버튼 텍스트 변경으로 변경사항 표시
                    self?.changePhotoButton.setTitle("사진 변경됨", for: .normal)
                    self?.changePhotoButton.setTitleColor(.systemOrange, for: .normal)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        
        if let selectedImage = image {
            self.selectedImage = selectedImage
            self.hasImageChanged = true
            self.profileImageView.image = selectedImage
            
            // 버튼 텍스트 변경으로 변경사항 표시
            changePhotoButton.setTitle("사진 변경됨", for: .normal)
            changePhotoButton.setTitleColor(.systemOrange, for: .normal)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
