//
//  AuthGate.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit
import FirebaseAuth

class AuthGate: UIViewController {
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkAuthenticationState()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.startAnimating()
    }
    
    func checkAuthenticationState() {
        // Firebase Auth 상태 변화 감지
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // 로그인된 상태 - 메인 앱으로 이동
                    print("사용자 로그인됨: \(user.email ?? "Unknown")")
                    self?.navigateToMainApp()
                } else {
                    // 로그인되지 않은 상태 - 로그인 화면으로 이동
                    print("사용자 로그인되지 않음")
                    self?.navigateToLogin()
                }
            }
        }
    }
    
    private func navigateToMainApp() {
        let mainApp = TabBarController()
        
        // 화면 전환 애니메이션
        if let window = view.window {
            window.rootViewController = mainApp
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
    
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        
        // 화면 전환 애니메이션
        if let window = view.window {
            window.rootViewController = loginVC
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
}
