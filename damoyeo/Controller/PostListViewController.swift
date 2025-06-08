import UIKit

class PostListViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    // MARK: - Properties
    private var posts: [Post] = [] // 임시로 빈 배열
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupNavigationBar()
        loadSampleData() // 임시 데이터
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "모집 게시물"
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationBar() {
        // Sort 버튼 (왼쪽)
        let sortButton = UIBarButtonItem(
            title: "Sort",
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )
        navigationItem.leftBarButtonItem = sortButton
        
        // Filter 버튼과 Add 버튼 (오른쪽)
        let filterButton = UIBarButtonItem(
            title: "Filter",
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPostTapped)
        )
        navigationItem.rightBarButtonItems = [addButton, filterButton]
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 셀 등록 (다음 단계에서 구현)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostCell")
    }
    
    // MARK: - Actions
    @objc private func sortButtonTapped() {
        print("Sort 버튼 탭됨")
        // TODO: 정렬 기능 구현
    }
    
    @objc private func filterButtonTapped() {
        print("Filter 버튼 탭됨")
        // TODO: 필터 기능 구현
    }
    
    @objc private func addPostTapped() {
        print("게시물 작성 버튼 탭됨")
        // TODO: 게시물 작성 화면으로 이동
    }
    
    // MARK: - Data
    private func loadSampleData() {
        // 임시 데이터 (다음 단계에서 실제 데이터로 교체)
        print("임시 데이터 로드됨")
    }
}

// MARK: - TableView DataSource & Delegate
extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 // 임시로 5개 셀
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
        cell.textLabel?.text = "게시물 \(indexPath.row + 1)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("게시물 \(indexPath.row + 1) 선택됨")
        // TODO: 게시물 상세 화면으로 이동
    }
}
