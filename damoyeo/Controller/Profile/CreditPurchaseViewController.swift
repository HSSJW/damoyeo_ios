import UIKit

class CreditPurchaseViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "크레딧 구매"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let currentCreditsLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 크레딧: 0"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        return stackView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private let paymentManager = MockPaymentManager.shared
    private var currentCredits = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentCredits()
        setupProductButtons()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "크레딧 구매"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, currentCreditsLabel, stackView, loadingIndicator].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            currentCreditsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            currentCreditsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            currentCreditsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: currentCreditsLabel.bottomAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupProductButtons() {
        for product in CreditProduct.allProducts {
            let productView = createProductView(for: product)
            stackView.addArrangedSubview(productView)
        }
    }
    
    private func createProductView(for product: CreditProduct) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = product.displayName
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = product.description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray
        
        let priceLabel = UILabel()
        priceLabel.text = product.price
        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)
        priceLabel.textColor = .systemBlue
        
        let purchaseButton = UIButton(type: .system)
        purchaseButton.setTitle("구매하기", for: .normal)
        purchaseButton.backgroundColor = .systemBlue
        purchaseButton.setTitleColor(.white, for: .normal)
        purchaseButton.layer.cornerRadius = 8
        purchaseButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        purchaseButton.tag = CreditProduct.allProducts.firstIndex(where: { $0.productId == product.productId }) ?? 0
        purchaseButton.addTarget(self, action: #selector(purchaseButtonTapped(_:)), for: .touchUpInside)
        
        [titleLabel, descriptionLabel, priceLabel, purchaseButton].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            priceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            
            purchaseButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            purchaseButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            purchaseButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            purchaseButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return containerView
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func purchaseButtonTapped(_ sender: UIButton) {
        let product = CreditProduct.allProducts[sender.tag]
        startPurchase(product: product)
    }
    
    private func startPurchase(product: CreditProduct) {
        loadingIndicator.startAnimating()
        
        paymentManager.purchaseCredits(productId: product.productId) { [weak self] result in
            DispatchQueue.main.async {
                self?.handlePurchaseResult(result, product: product)
            }
        }
    }
    
    private func handlePurchaseResult(_ result: MockPaymentManager.PurchaseResult, product: CreditProduct) {
        switch result {
        case .success(let credits, let transactionId):
            paymentManager.sendPurchaseToServer(
                transactionId: transactionId,
                productId: product.productId,
                credits: credits
            ) { [weak self] success in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    
                    if success {
                        self?.showSuccessAlert(credits: credits)
                        self?.loadCurrentCredits()
                    } else {
                        self?.showErrorAlert(message: "서버 연동 실패. 잠시 후 다시 시도해주세요.")
                    }
                }
            }
            
        case .failure(let error):
            loadingIndicator.stopAnimating()
            showErrorAlert(message: error)
            
        case .cancelled:
            loadingIndicator.stopAnimating()
        }
    }
    
    private func loadCurrentCredits() {
        // TODO: 실제 서버에서 현재 크레딧 로드
        currentCredits = UserDefaults.standard.integer(forKey: "userCredits")
        currentCreditsLabel.text = "현재 크레딧: \(currentCredits)"
    }
    
    private func showSuccessAlert(credits: Int) {
        let alert = UIAlertController(
            title: "구매 완료! 🎉",
            message: "\(credits) 크레딧이 지급되었습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "구매 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
