import Foundation
import UIKit
import RevenueCat
class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        customizeTabBar()
    }
    
    func setupTabs() {
        let tab1 = UIViewController()
        
        tab1.view.backgroundColor = .white
        
        tab1.tabBarItem = UITabBarItem(title: "Magic", image: UIImage(systemName: "star.fill"), tag: 0)
        
        let tab2 = UIViewController()
        
        tab2.view.backgroundColor = .white
        
        tab2.tabBarItem = UITabBarItem(title: "Photos", image: UIImage(systemName: "photo"), tag: 1)
        
        let tab3 = UIViewController()
        
        tab3.view.backgroundColor = .white
        
        tab3.tabBarItem = UITabBarItem(title: "Camera", image: UIImage(systemName: "camera"), tag: 2)
        
        let tab4 = UIViewController()
        
        tab4.view.backgroundColor = .white
        
        tab4.tabBarItem = UITabBarItem(title: "Voice", image: UIImage(systemName: "mic"), tag: 3)
        
        let tab5 = UIViewController()
        
        tab5.view.backgroundColor = .white
        
        tab5.tabBarItem = UITabBarItem(title: "Add", image: UIImage(systemName: "plus.circle"), tag: 4)
        
        viewControllers = [tab1, tab2, tab3, tab4, tab5]
    }

    func customizeTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .gray
    }
}
