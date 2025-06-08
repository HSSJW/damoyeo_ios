//
//  TabBarController.swift
//  damoyeo
//
//  Created by 송진우 on 6/7/25.
//


import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBar()
    }
    
    private func setupTabBar() {
        // 각 뷰 컨트롤러 생성
        let favoriteVC = FavoriteViewController()
        let chatVC = ChatViewController()
        let postListVC = PostListViewController()
        let activityVC = ActivityViewController()
        let profileVC = ProfileViewController()
        
        // 탭바 아이템 설정
        favoriteVC.tabBarItem = UITabBarItem(title: "찜목록", image: UIImage(systemName: "heart"), tag: 0)
        chatVC.tabBarItem = UITabBarItem(title: "채팅", image: UIImage(systemName: "message"), tag: 1)
        postListVC.tabBarItem = UITabBarItem(title: "게시물", image: UIImage(systemName: "list.bullet"), tag: 2)
        activityVC.tabBarItem = UITabBarItem(title: "활동", image: UIImage(systemName: "clock"), tag: 3)
        profileVC.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person"), tag: 4)
        
        // NavigationController 추가
        let favoriteNav = UINavigationController(rootViewController: favoriteVC)
        let chatNav = UINavigationController(rootViewController: chatVC)
        let postListNav = UINavigationController(rootViewController: postListVC)
        let activityNav = UINavigationController(rootViewController: activityVC)
        let profileNav = UINavigationController(rootViewController: profileVC)
        
        
        // 뷰 컨트롤러들을 탭바에 설정 각각 0 1 2 3 4
        viewControllers = [favoriteNav, chatNav, postListNav, activityNav, profileNav]
        
        // 기본 선택 탭 설정 (게시물 탭 = 인덱스 2)
        selectedIndex = 2
    }
}
