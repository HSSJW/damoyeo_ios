//
//  PostTableViewCell.swift
//  damoyeo
//
//  Created by 송진우 on 6/8/25.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.numberOfLines = 2
        return label
    }()
    
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemBlue
        return label
    }()
    
    private let participantLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(postImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(participantLabel)
        
        // Auto Layout 비활성화
        [postImageView, titleLabel, contentLabel, tagLabel, participantLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Layout 제약 조건
        NSLayoutConstraint.activate([
            // 이미지 뷰
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            postImageView.widthAnchor.constraint(equalToConstant: 80),
            postImageView.heightAnchor.constraint(equalToConstant: 80),
            postImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            // 제목 라벨
            titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // 내용 라벨
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // 태그 라벨
            tagLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            tagLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            
            // 참가자 라벨
            participantLabel.leadingAnchor.constraint(equalTo: tagLabel.trailingAnchor, constant: 8),
            participantLabel.topAnchor.constraint(equalTo: tagLabel.topAnchor),
            participantLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with post: Post) {
        titleLabel.text = post.title
        contentLabel.text = post.content.count > 50 ? String(post.content.prefix(50)) + "..." : post.content
        tagLabel.text = "📍 \(post.tag)"
        participantLabel.text = "👥 0/\(post.recruit)" // TODO: 실제 참가자 수로 교체
        
        // 이미지 로딩
        loadImage(from: post.imageUrls.first ?? post.imageUrl)
    }
    
    private func loadImage(from urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            postImageView.image = UIImage(systemName: "photo.fill")
            return
        }
        
        // 간단한 이미지 로딩 (나중에 SDWebImage 등으로 개선 가능)
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.postImageView.image = UIImage(systemName: "photo.fill")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.postImageView.image = image
            }
        }.resume()
    }
}
