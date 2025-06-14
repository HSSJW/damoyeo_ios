import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    private let tableView: UITableView = {
            let tableView = UITableView()
            tableView.translatesAutoresizingMaskIntoConstraints = false
            return tableView
        }()
    
    private var chatRooms: [ChatRoom] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupConstraints() // 제약조건 추가
        loadChatRooms()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "채팅 목록"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // tableView를 뷰에 추가
                view.addSubview(tableView)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatRoomCell.self, forCellReuseIdentifier: "ChatRoomCell")
        tableView.separatorStyle = .singleLine
    }
    
    private func setupConstraints() {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    
    
    private func loadChatRooms() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("chats")
            .whereField("users", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                
                if let error = error {
                    print("Error fetching chat rooms: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.chatRooms = []
                    self?.tableView.reloadData()
                    return
                }
                
                self?.chatRooms = documents.compactMap { doc in
                    ChatRoom(document: doc)
                }.sorted { (room1, room2) in
                    // 고정된 채팅방을 먼저 표시
                    if room1.pinned != room2.pinned {
                        return room1.pinned && !room2.pinned
                    }
                    // 그 다음 최신 메시지 순으로 정렬
                    return room1.timestamp?.compare(room2.timestamp ?? Date()) == .orderedDescending
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
    
    // 새로운 채팅방 생성 또는 기존 채팅방 가져오기
    func createOrGetChatRoom(with otherUserId: String, completion: @escaping (String?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        // 기존 채팅방 확인
        db.collection("chats")
            .whereField("users", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                
                if let error = error {
                    print("Error checking existing chat rooms: \(error)")
                    completion(nil)
                    return
                }
                
                // 상대방과의 기존 채팅방 찾기
                for document in snapshot?.documents ?? [] {
                    let users = document.data()["users"] as? [String] ?? []
                    if users.contains(otherUserId) {
                        completion(document.documentID)
                        return
                    }
                }
                
                // 새 채팅방 생성
                let chatRoomId = UUID().uuidString
                let newChatRoom = ChatRoom(
                    id: chatRoomId,
                    users: [currentUserId, otherUserId],
                    lastMessage: "",
                    timestamp: Date(),
                    pinned: false
                )
                
                self?.db.collection("chats").document(chatRoomId).setData(newChatRoom.toDictionary()) { error in
                    if let error = error {
                        print("Error creating new chat room: \(error)")
                        completion(nil)
                    } else {
                        completion(chatRoomId)
                    }
                }
            }
    }
    
    private func pinChatRoom(_ chatRoomId: String) {
        db.collection("chats").document(chatRoomId).updateData(["pinned": true])
    }
    
    private func unpinChatRoom(_ chatRoomId: String) {
        db.collection("chats").document(chatRoomId).updateData(["pinned": false])
    }
    
    private func exitChatRoom(_ chatRoomId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("chats").document(chatRoomId).updateData([
            "users": FieldValue.arrayRemove([currentUserId])
        ]) { [weak self] error in
            if let error = error {
                print("Error exiting chat room: \(error)")
                return
            }
            
            // 채팅방에 사용자가 남아있지 않으면 삭제
            self?.db.collection("chats").document(chatRoomId).getDocument { document, error in
                if let document = document,
                   let users = document.data()?["users"] as? [String],
                   users.isEmpty {
                    self?.db.collection("chats").document(chatRoomId).delete()
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomCell", for: indexPath) as! ChatRoomCell
        let chatRoom = chatRooms[indexPath.row]
        cell.configure(with: chatRoom)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chatRoom = chatRooms[indexPath.row]
        let otherUserId = chatRoom.getOtherUserId()
        
        let chatDetailVC = ChatDetailViewController()
        chatDetailVC.chatId = chatRoom.id
        chatDetailVC.otherUserId = otherUserId
        
        navigationController?.pushViewController(chatDetailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // 스와이프 액션 (고정, 나가기)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let chatRoom = chatRooms[indexPath.row]
        
        let pinAction = UIContextualAction(style: .normal, title: chatRoom.pinned ? "고정 해제" : "고정") { [weak self] _, _, completion in
            if chatRoom.pinned {
                self?.unpinChatRoom(chatRoom.id)
            } else {
                self?.pinChatRoom(chatRoom.id)
            }
            completion(true)
        }
        pinAction.backgroundColor = .systemBlue
        
        let exitAction = UIContextualAction(style: .destructive, title: "나가기") { [weak self] _, _, completion in
            self?.exitChatRoom(chatRoom.id)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [exitAction, pinAction])
    }
}
