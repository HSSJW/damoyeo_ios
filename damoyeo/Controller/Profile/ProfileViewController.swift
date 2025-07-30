import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    // MARK: - UI Components
    // ScrollView 제거하고 단일 TableView 사용
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        return tableView
    }()
    
    // MARK: - Properties
    private var currentFirebaseUser: FirebaseAuth.User?
    private var customUserInfo: [String: Any] = [:]
    private let menuItems = [
        ("크레딧 구매", "creditcard"),           // 🆕 추가
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
        loadUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "프로필"
        
        // TableView 설정
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.register(ProfileHeaderCell.self, forCellReuseIdentifier: "ProfileHeaderCell")
        
        // TableView 추가
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        self.currentFirebaseUser = firebaseUser
        
        // Firestore에서 사용자 정보 가져오기
        let db = Firestore.firestore()
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("사용자 정보 로드 실패: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    self?.customUserInfo = data
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // 🆕 크레딧 구매 메서드 추가
    private func showCreditPurchase() {
        let creditPurchaseVC = CreditPurchaseViewController()
        let navController = UINavigationController(rootViewController: creditPurchaseVC)
        present(navController, animated: true)
    }
    
    // MARK: - Actions
    private func editProfile() {
        let editVC = EditProfileViewController(userInfo: customUserInfo)
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    private func changePassword() {
        let changePasswordVC = ChangePasswordViewController()
        let navController = UINavigationController(rootViewController: changePasswordVC)
        present(navController, animated: true)
    }
    
    private func showActivity() {
        guard let userId = currentFirebaseUser?.uid else { return }
        let activityVC = MyActivityViewController(userId: userId)
        navigationController?.pushViewController(activityVC, animated: true)
    }
    
    private func logout() {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃 하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                
                let loginVC = LoginViewController()
                
                if let window = self.view.window {
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                    
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                }
                
            } catch {
                print("로그아웃 실패: \(error.localizedDescription)")
                self.showAlert(message: "로그아웃 실패: \(error.localizedDescription)")
            }
        })
        
        present(alert, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // 0: 프로필 헤더, 1: 메뉴 목록
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // 프로필 헤더 셀
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileHeaderCell", for: indexPath) as! ProfileHeaderCell
            
            let email = currentFirebaseUser?.email ?? ""
            let nickname = customUserInfo["user_nickname"] as? String ?? "닉네임 없음"
            let postCount = customUserInfo["user_PostCount"] as? Int ?? 0
            let profileImageUrl = customUserInfo["profile_image"] as? String
            
            cell.configure(email: email, nickname: nickname, postCount: postCount, profileImageUrl: profileImageUrl)
            cell.selectionStyle = .none
            
            return cell
        } else {
            // 메뉴 셀
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 1 else { return }
        
        switch indexPath.row {
        case 0: showCreditPurchase()      // 🆕 추가
        case 1: editProfile()
        case 2: changePassword()
        case 3: showActivity()
        case 4: logout()
        default: break
        }
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 300 : 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.1 : 20
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
}

// MARK: - ProfileHeaderCell
class ProfileHeaderCell: UITableViewCell {
    
    // MARK: - UI Components
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        let statsStackView = UIStackView(arrangedSubviews: [postsCountLabel, postsTextLabel])
        statsStackView.axis = .vertical
        statsStackView.spacing = 4
        
        [profileImageView, nicknameLabel, emailLabel, statsStackView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
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
            statsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    func configure(email: String, nickname: String, postCount: Int, profileImageUrl: String?) {
        emailLabel.text = email
        nicknameLabel.text = nickname
        postsCountLabel.text = "\(postCount)"
        
        // 프로필 이미지 로드
        if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
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
}
