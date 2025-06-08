//
//  LoginViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.3.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "다모여"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = ["로그인", "회원가입"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    // 로그인/회원가입 공통 필드
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "이메일"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "비밀번호"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        return textField
    }()
    
    // 회원가입 전용 필드들
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "이름"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "닉네임"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "전화번호"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .phonePad
        return textField
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그인", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var isLoginMode: Bool = true {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(logoImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(segmentedControl)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(nameTextField)
        contentView.addSubview(nicknameTextField)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(actionButton)
        contentView.addSubview(loadingIndicator)
        
        setupConstraints()
        updateUI()
    }
    
    private func setupConstraints() {
        [scrollView, contentView, logoImageView, titleLabel, segmentedControl,
         emailTextField, passwordTextField, nameTextField, nicknameTextField,
         phoneTextField, actionButton, loadingIndicator].forEach {
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
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Email
            emailTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 32),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Name (회원가입 시에만 표시)
            nameTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Nickname
            nicknameTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            nicknameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nicknameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Phone
            phoneTextField.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 16),
            phoneTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Action Button
            actionButton.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 32),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    private func updateUI() {
        nameTextField.isHidden = isLoginMode
        nicknameTextField.isHidden = isLoginMode
        phoneTextField.isHidden = isLoginMode
        
        actionButton.setTitle(isLoginMode ? "로그인" : "회원가입", for: .normal)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        isLoginMode = segmentedControl.selectedSegmentIndex == 0
    }
    
    @objc private func actionButtonTapped() {
        if isLoginMode {
            login()
        } else {
            signUp()
        }
    }
    
    // MARK: - Authentication
    private func login() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "이메일과 비밀번호를 입력해주세요.")
            return
        }
        
        loadingIndicator.startAnimating()
        actionButton.setTitle("", for: .normal)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.actionButton.setTitle("로그인", for: .normal)
                
                if let error = error {
                    self?.showAlert(message: "로그인 실패: \(error.localizedDescription)")
                } else {
                    // 로그인 성공
                    self?.navigateToMainApp()
                }
            }
        }
    }
    
    private func signUp() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let name = nameTextField.text, !name.isEmpty,
              let nickname = nicknameTextField.text, !nickname.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            showAlert(message: "모든 필드를 입력해주세요.")
            return
        }
        
        loadingIndicator.startAnimating()
        actionButton.setTitle("", for: .normal)
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.actionButton.setTitle("회원가입", for: .normal)
                    self?.showAlert(message: "회원가입 실패: \(error.localizedDescription)")
                }
                return
            }
            
            // Firestore에 사용자 정보 저장
            guard let userId = result?.user.uid else { return }
            self?.saveUserInfo(userId: userId, name: name, nickname: nickname, phone: phone, email: email)
        }
    }
    
    private func saveUserInfo(userId: String, name: String, nickname: String, phone: String, email: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "user_name": name,
            "user_nickname": nickname,
            "user_phoneNum": phone,
            "user_email": email,
            "user_createdAt": FieldValue.serverTimestamp(),
            "user_postCount": 0
        ]
        
        db.collection("users").document(userId).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.actionButton.setTitle("회원가입", for: .normal)
                
                if let error = error {
                    self?.showAlert(message: "사용자 정보 저장 실패: \(error.localizedDescription)")
                } else {
                    // 회원가입 성공
                    self?.navigateToMainApp()
                }
            }
        }
    }
    
    private func navigateToMainApp() {
        print("🎯 LoginVC: 직접 메인 앱으로 이동")
        
        let mainApp = TabBarController()
        
        if let window = view.window {
            print("🪟 LoginVC: Window 찾음, 직접 전환")
            window.rootViewController = mainApp
            window.makeKeyAndVisible()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil) 
        } else {
            print("❌ LoginVC: Window를 찾을 수 없음")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
