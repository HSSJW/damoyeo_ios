//
//  AIPostGeneratorViewController.swift
//  damoyeo
//
//  AI를 활용한 자연어 게시물 생성기
//

import UIKit

class AIPostGeneratorViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI 게시물 생성기"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "원하는 모임을 자연어로 설명해보세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let exampleLabel: UILabel = {
        let label = UILabel()
        label.text = "💡 예시: \"이번 주말에 한강에서 치킨 먹으면서 친목 도모하고 싶어요. 5명 정도 모였으면 좋겠고 1인당 2만원 정도 예상해요\""
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray2
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .systemGray6.withAlphaComponent(0.5)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        // 패딩 추가를 위한 설정
        return label
    }()
    
    private let inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 12
        textView.backgroundColor = .systemBackground
        textView.text = ""
        textView.textColor = .label
        return textView
    }()
    
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✨ AI로 게시물 생성하기", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // 생성된 게시물 미리보기 영역
    private let previewContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private let previewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "✨ 생성된 게시물 미리보기"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let previewContentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("현재 내용 적용", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    private let rejectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🔄 다시 생성", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // MARK: - Properties
    private var generatedPostData: GeneratedPostData?
    var onPostGenerated: ((GeneratedPostData) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, subtitleLabel, exampleLabel, inputTextView, generateButton,
         loadingIndicator, previewContainerView].forEach {
            contentView.addSubview($0)
        }
        
        [previewTitleLabel, previewContentLabel, acceptButton, rejectButton].forEach {
            previewContainerView.addSubview($0)
        }
        
        setupConstraints()
        setupExampleLabel()
    }
    
    private func setupExampleLabel() {
        // 패딩을 위한 설정
        exampleLabel.textAlignment = .left
        // 텍스트 인셋을 위해 attributedText 사용
        let text = "💡 예시: \"이번 주말에 한강에서 치킨 먹으면서 친목 도모하고 싶어요. 5명 정도 모였으면 좋겠고 1인당 2만원 정도 예상해요\""
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 12
        paragraphStyle.headIndent = 12
        paragraphStyle.tailIndent = -12
        
        let attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.systemGray2,
            .paragraphStyle: paragraphStyle
        ])
        exampleLabel.attributedText = attributedText
    }
    
    private func setupConstraints() {
        [scrollView, contentView, titleLabel, subtitleLabel, exampleLabel, inputTextView,
         generateButton, loadingIndicator, previewContainerView,
         previewTitleLabel, previewContentLabel, acceptButton, rejectButton].forEach {
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
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Example
            exampleLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            exampleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            exampleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            exampleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            // Input TextView
            inputTextView.topAnchor.constraint(equalTo: exampleLabel.bottomAnchor, constant: 20),
            inputTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inputTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inputTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // Generate Button
            generateButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 24),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            generateButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: generateButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: generateButton.centerYAnchor),
            
            // Preview Container
            previewContainerView.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 24),
            previewContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            previewContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Preview Title
            previewTitleLabel.topAnchor.constraint(equalTo: previewContainerView.topAnchor, constant: 20),
            previewTitleLabel.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor, constant: 16),
            previewTitleLabel.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor, constant: -16),
            
            // Preview Content
            previewContentLabel.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 16),
            previewContentLabel.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor, constant: 16),
            previewContentLabel.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor, constant: -16),
            
            // Buttons
            acceptButton.topAnchor.constraint(equalTo: previewContentLabel.bottomAnchor, constant: 24),
            acceptButton.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor, constant: 16),
            acceptButton.trailingAnchor.constraint(equalTo: previewContainerView.centerXAnchor, constant: -8),
            acceptButton.heightAnchor.constraint(equalToConstant: 48),
            acceptButton.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: -20),
            
            rejectButton.topAnchor.constraint(equalTo: previewContentLabel.bottomAnchor, constant: 24),
            rejectButton.leadingAnchor.constraint(equalTo: previewContainerView.centerXAnchor, constant: 8),
            rejectButton.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor, constant: -16),
            rejectButton.heightAnchor.constraint(equalToConstant: 48),
            rejectButton.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        
        inputTextView.delegate = self
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func generateButtonTapped() {
        guard let inputText = inputTextView.text,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "모임에 대한 설명을 입력해주세요.")
            return
        }
        
        startGeneration()
        generatePostWithAI(inputText: inputText)
    }
    
    @objc private func acceptButtonTapped() {
        guard let generatedData = generatedPostData else { return }
        onPostGenerated?(generatedData)
        dismiss(animated: true)
    }
    
    @objc private func rejectButtonTapped() {
        hidePreview()
    }
    
    // MARK: - AI 게시물 생성
    private func generatePostWithAI(inputText: String) {
        print("🚀 AI 생성 시작: \(inputText)")
        
        FirebaseAIManager.shared.generatePost(from: inputText) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopGeneration()
                
                switch result {
                case .success(let postData):
                    print("✅ AI 생성 성공: \(postData.title)")
                    self?.generatedPostData = postData
                    self?.showPreview(postData)
                    
                case .failure(let error):
                    print("❌ AI 생성 실패: \(error)")
                    self?.showAlert(message: "AI 생성 중 오류가 발생했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - UI Updates
    private func startGeneration() {
        loadingIndicator.startAnimating()
        generateButton.setTitle("", for: .normal)
        generateButton.isEnabled = false
        hidePreview()
        
        // 키보드 숨기기
        inputTextView.resignFirstResponder()
    }
    
    private func stopGeneration() {
        loadingIndicator.stopAnimating()
        generateButton.setTitle("✨ AI로 게시물 생성하기", for: .normal)
        generateButton.isEnabled = true
    }
    
    private func showPreview(_ postData: GeneratedPostData) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM월 dd일 HH:mm"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let costText = numberFormatter.string(from: NSNumber(value: postData.cost)) ?? "0"
        
        let previewText = """
        📝 제목: \(postData.title)
        
        📍 지역: \(postData.region)
        📍 장소: \(postData.address) \(postData.detailAddress)
        
        👥 모집인원: \(postData.recruit)명
        💰 예상비용: \(costText)원
        📅 모임시간: \(dateFormatter.string(from: postData.meetingTime))
        🏷️ 카테고리: \(postData.category)
        
        📖 내용:
        \(postData.content)
        """
        
        previewContentLabel.text = previewText
        previewContainerView.isHidden = false
        
        // 애니메이션으로 부드럽게 표시
        previewContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.previewContainerView.alpha = 1
        }
        
        // 스크롤을 미리보기 영역으로 이동
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
            if bottomOffset.y > 0 {
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    
    private func hidePreview() {
        UIView.animate(withDuration: 0.3) {
            self.previewContainerView.alpha = 0
        } completion: { _ in
            self.previewContainerView.isHidden = true
            self.generatedPostData = nil
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension AIPostGeneratorViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 텍스트뷰에 포커스가 갔을 때의 처리
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // 텍스트뷰에서 포커스가 사라졌을 때의 처리
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 글자 수 제한 (선택사항)
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        // 500자 제한
        return updatedText.count <= 500
    }
}
