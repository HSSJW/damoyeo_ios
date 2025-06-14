import UIKit
import FirebaseAuth
import FirebaseFirestore

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
        // 기본 프로필 이미지
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemGray3
        
        // 사용자 정보 로드
        nameTextField.text = userInfo["user_name"] as? String
        nicknameTextField.text = userInfo["user_nickname"] as? String
        phoneTextField.text = userInfo["user_phoneNum"] as? String
        emailTextField.text = userInfo["user_email"] as? String ?? Auth.auth().currentUser?.email
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let updatedData: [String: Any] = [
            "user_name": nameTextField.text ?? "",
            "user_nickname": nicknameTextField.text ?? "",
            "user_phoneNum": phoneTextField.text ?? ""
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(updatedData) { [weak self] error in
            DispatchQueue.main.async {
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
