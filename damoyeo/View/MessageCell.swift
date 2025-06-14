//
//  MessageCell.swift
//  damoyeo
//
//  Created by 송진우 on 6/14/25.
//

import UIKit
import Firebase
import FirebaseAuth

class MessageCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let readStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "1"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Constraints that will be activated/deactivated based on message sender
    private var leadingConstraints: [NSLayoutConstraint] = []
    private var trailingConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageContainerView)
        contentView.addSubview(readStatusLabel)
        messageContainerView.addSubview(messageLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Profile image constraints
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Name label constraints
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            nameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor)
        ])
        
        // Message label constraints within container
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -12)
        ])
        
        // Container constraints for incoming messages (left side)
        leadingConstraints = [
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageContainerView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            messageContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.centerXAnchor, constant: 50),
            messageContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ]
        
        // Container constraints for outgoing messages (right side)
        trailingConstraints = [
            messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.centerXAnchor, constant: -50),
            messageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            readStatusLabel.trailingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: -4),
            readStatusLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor)
        ]
    }
    
    // MARK: - Configuration
    func configure(with message: ChatMessage, otherUserProfileImage: String?, otherUserName: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let isCurrentUser = message.senderId == currentUserId
        
        // Configure message appearance based on sender
        if isCurrentUser {
            // Outgoing message
            NSLayoutConstraint.deactivate(leadingConstraints)
            NSLayoutConstraint.activate(trailingConstraints)
            
            messageContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
            messageLabel.textColor = .white
            
            profileImageView.isHidden = true
            nameLabel.isHidden = true
            readStatusLabel.isHidden = message.isRead
            
        } else {
            // Incoming message
            NSLayoutConstraint.deactivate(trailingConstraints)
            NSLayoutConstraint.activate(leadingConstraints)
            
            messageContainerView.backgroundColor = .systemGray5
            messageLabel.textColor = .label
            
            profileImageView.isHidden = false
            nameLabel.isHidden = false
            readStatusLabel.isHidden = true
            
            // Set profile image and name
            nameLabel.text = otherUserName
            
            if let profileImageUrl = otherUserProfileImage,
               !profileImageUrl.isEmpty,
               let url = URL(string: profileImageUrl) {
                loadImage(from: url)
            } else {
                profileImageView.image = UIImage(systemName: "person.circle.fill")
                profileImageView.tintColor = .systemGray3
            }
        }
        
        messageLabel.text = message.message
        
        // Update corner radius based on message side
        if isCurrentUser {
            messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        messageLabel.text = nil
        nameLabel.text = nil
        readStatusLabel.isHidden = true
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(leadingConstraints)
        NSLayoutConstraint.deactivate(trailingConstraints)
    }
}

// MARK: - DateSeparatorCell
class DateSeparatorCell: UITableViewCell {
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(separatorLine)
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            separatorLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: 24),
            dateLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            contentView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        dateLabel.text = formatter.string(from: date)
    }
}
