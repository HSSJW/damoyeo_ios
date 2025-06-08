//
//  ProfileViewController.swift
//  damoyeo
//
//  Created by 송진우 on 6/7/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 프로필 헤더
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 60
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        return imageView
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    // 통계
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    private let postsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let postsTextLabel: UILabel = {
        let label = UILabel()
        label.text = "게시물"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    // 메뉴 테이블뷰
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    // MARK: - Properties
    private var currentUser: User?
    private var userInfo: [String: Any] = [:]
    private let menuItems = [
        ("내 정보 수정", "person.crop.circle"),
        ("비밀번호 변경", "key"),
        ("활동 내역", "clock"),
        ("로그아웃", "rectangle.portrait.and.arrow.right")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData() // 화면이 나타날 때마다 데이터 새로고침
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "프로필"
        
        setupScrollView()
        setupProfileHeader()
        setupStatsView()
        setupTableView()
        setupConstraints()
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupProfileHeader() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(emailLabel)
        
        [profileImageView, nicknameLabel, emailLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupStatsView() {
        let postsStackView = UIStackView(arrangedSubviews: [postsCountLabel, postsTextLabel])
        postsStackView.axis = .vertical
        postsStackView.spacing = 4
        
        statsStackView.addArrangedSubview(postsStackView)
        
        contentView.addSubview(statsStackView)
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        
        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
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
            
            // Nickname
            nicknameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nicknameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nicknameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Email
            emailLabel.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Stats
            statsStackView.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            statsStackView.heightAnchor.constraint(equalToConstant: 60),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 32),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 240), // 4개 메뉴 * 60 높이
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        self.currentUser = user
        emailLabel.text = user.email
        
        // Firestore에서 사용자 정보 가져오기
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("사용자 정보 로드 실패: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    self?.userInfo = data
                    self?.updateUI(with: data)
                }
            }
        }
    }
    
    private func updateUI(with data: [String: Any]) {
        // 닉네임
        if let nickname = data["user_nickname"] as? String {
            nicknameLabel.text = nickname
        } else {
            nicknameLabel.text = "닉네임 없음"
        }
        
        // 게시물 수
        if let postCount = data["user_postCount"] as? Int {
            postsCountLabel.text = "\(postCount)"
        } else {
            postsCountLabel.text = "0"
        }
        
        // 프로필 이미지 (기본 이미지)
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemGray3
    }
    
    // MARK: - Actions
    private func editProfile() {
        let editVC = EditProfileViewController(userInfo: userInfo)
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    private func changePassword() {
        let changePasswordVC = ChangePasswordViewController()
        let navController = UINavigationController(rootViewController: changePasswordVC)
        present(navController, animated: true)
    }
    
    private func showActivity() {
        guard let userId = currentUser?.uid else { return }
        let activityVC = MyActivityViewController(userId: userId)
        navigationController?.pushViewController(activityVC, animated: true)
    }
    
    private func logout() {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃 하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                
                // 직접 LoginViewController로 이동
                let loginVC = LoginViewController()
                
                if let window = self.view.window {
    
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                    
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil) { _ in
                    
                    }
                } else {
                
                }
                
            } catch {
                print("로그아웃 실패: \(error.localizedDescription)")
                self.showAlert(message: "로그아웃 실패: \(error.localizedDescription)")
            }
        })
        
        present(alert, animated: true)
    }

    // Alert 표시를 위한 헬퍼 메서드 추가
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        
        let (title, iconName) = menuItems[indexPath.row]
        cell.textLabel?.text = title
        cell.imageView?.image = UIImage(systemName: iconName)
        cell.accessoryType = .disclosureIndicator
        
        // 로그아웃 셀은 빨간색으로
        if indexPath.row == menuItems.count - 1 {
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.tintColor = .systemRed
        } else {
            cell.textLabel?.textColor = .label
            cell.imageView?.tintColor = .systemBlue
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: editProfile()
        case 1: changePassword()
        case 2: showActivity()
        case 3: logout()
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
