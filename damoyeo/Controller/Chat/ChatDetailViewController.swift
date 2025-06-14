import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatDetailViewController: UIViewController {
    
    // MARK: - Properties
    var chatId: String!
    var otherUserId: String!
    
    private var messages: [ChatMessage] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    private var otherUserName = "Loading..."
    private var otherUserProfileImage: String?
    
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let messageInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "메시지를 입력하세요..."
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var messageInputViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupKeyboardObservers()
        fetchOtherUserData()
        loadMessages()
        markMessagesAsRead()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        listener?.remove()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(messageInputView)
        messageInputView.addSubview(textField)
        messageInputView.addSubview(sendButton)
        
        messageInputViewBottomConstraint = messageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // TableView
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            
            // Message Input View
            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputView.heightAnchor.constraint(equalToConstant: 60),
            messageInputViewBottomConstraint,
            
            // Text Field
            textField.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: messageInputView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            // Send Button
            sendButton.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: messageInputView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.delegate = self
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.register(DateSeparatorCell.self, forCellReuseIdentifier: "DateSeparatorCell")
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    private func fetchOtherUserData() {
        db.collection("users").document(otherUserId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            guard let document = document, document.exists else { return }
            
            if let user = User(document: document) {
                DispatchQueue.main.async {
                    self?.otherUserName = user.userName
                    self?.otherUserProfileImage = user.profileImage
                    self?.title = "\(user.userName)님과의 채팅방"
                }
            }
        }
    }
    
    private func loadMessages() {
        listener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.messages = documents.compactMap { doc in
                    ChatMessage(document: doc)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottom()
                    self?.markMessagesAsRead()
                }
            }
    }
    
    private func markMessagesAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .whereField("senderId", isEqualTo: otherUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                
                if let error = error {
                    print("Error fetching unread messages: \(error)")
                    return
                }
                
                let batch = self?.db.batch()
                
                snapshot?.documents.forEach { document in
                    batch?.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("Error marking messages as read: \(error)")
                    }
                }
            }
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        sendMessage()
    }
    
    @objc private func textFieldDidChange() {
        sendButton.isEnabled = !(textField.text?.isEmpty ?? true)
    }
    
    private func sendMessage() {
        guard let messageText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageText.isEmpty,
              let currentUser = Auth.auth().currentUser else { return }
        
        let customMessageId = "\(currentUser.uid)_\(Date().timeIntervalSince1970 * 1000)"
        
        let message = ChatMessage(
            messageId: customMessageId,
            senderId: currentUser.uid,
            senderName: currentUser.displayName ?? "Unknown",
            message: messageText,
            timestamp: Date(),
            isRead: false
        )
        
        // Clear text field immediately
        textField.text = ""
        sendButton.isEnabled = false
        
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .document(customMessageId)
            .setData(message.toDictionary()) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
        
        // Update last message in chat room
        db.collection("chats").document(chatId).updateData([
            "lastMessage": messageText,
            "timestamp": FieldValue.serverTimestamp()
        ])
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: duration) {
            self.messageInputViewBottomConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }
        
        scrollToBottom()
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        UIView.animate(withDuration: duration) {
            self.messageInputViewBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.configure(with: message, otherUserProfileImage: otherUserProfileImage, otherUserName: otherUserName)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate
extension ChatDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
