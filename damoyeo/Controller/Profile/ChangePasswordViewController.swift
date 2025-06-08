//
//  ChangePasswordViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseAuth

class ChangePasswordViewController: UIViewController {
    
    // MARK: - UI Components
    private let currentPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "현재 비밀번호"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let newPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "새 비밀번호 (6자 이상)"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "새 비밀번호 확인"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let changePasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("비밀번호 변경", for: .normal)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "비밀번호 변경"
        
        view.addSubview(currentPasswordTextField)
        view.addSubview(newPasswordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(changePasswordButton)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
        setupActions()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupConstraints() {
        [currentPasswordTextField, newPasswordTextField, confirmPasswordTextField,
         changePasswordButton, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Current Password
            currentPasswordTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            currentPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            currentPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            currentPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // New Password
            newPasswordTextField.topAnchor.constraint(equalTo: currentPasswordTextField.bottomAnchor, constant: 20),
            newPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            newPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            newPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Confirm Password
            confirmPasswordTextField.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Change Password Button
            changePasswordButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 40),
            changePasswordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            changePasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            changePasswordButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: changePasswordButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: changePasswordButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        changePasswordButton.addTarget(self, action: #selector(changePasswordTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func changePasswordTapped() {
        guard let currentPassword = currentPasswordTextField.text, !currentPassword.isEmpty,
              let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "모든 필드를 입력해주세요.")
            return
        }
        
        guard newPassword.count >= 6 else {
            showAlert(message: "새 비밀번호는 6자 이상이어야 합니다.")
            return
        }
        
        guard newPassword == confirmPassword else {
            showAlert(message: "새 비밀번호가 일치하지 않습니다.")
            return
        }
        
        changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    private func changePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }
        
        loadingIndicator.startAnimating()
        changePasswordButton.setTitle("", for: .normal)
        
        // 재인증
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.changePasswordButton.setTitle("비밀번호 변경", for: .normal)
                    self?.showAlert(message: "현재 비밀번호가 올바르지 않습니다.")
                }
                return
            }
            
            // 비밀번호 변경
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.changePasswordButton.setTitle("비밀번호 변경", for: .normal)
                    
                    if let error = error {
                        self?.showAlert(message: "비밀번호 변경 실패: \(error.localizedDescription)")
                    } else {
                        self?.showAlert(message: "비밀번호가 성공적으로 변경되었습니다.") {
                            self?.dismiss(animated: true)
                        }
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
