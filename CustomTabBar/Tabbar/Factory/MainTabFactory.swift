//
//  Created by 华博-技术支撑 on 2026/1/6.
//

import UIKit

struct MainTabFactory {
    static func create() -> TabContainerController {
        // 1. Create ViewControllers
        let homeVC = createDemoViewController(title: "首页", color: .systemCyan)
        let discoverVC = createDemoViewController(title: "发现", color: .systemMint)
        let messageVC = createDemoViewController(title: "消息", color: .systemIndigo)
        let profileVC = createDemoViewController(title: "我的", color: .systemTeal)
        
        // 2. Create Configurations
        let homeConfig = TabItemConfigurationModel(
            title: "首页",
            normalImage: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill"),
            analyticsIdentifier: "tab_home"
        )
        
        let discoverConfig = TabItemConfigurationModel(
            title: "发现",
            normalImage: UIImage(systemName: "safari"),
            selectedImage: UIImage(systemName: "safari.fill"),
            analyticsIdentifier: "tab_discover"
        )
        
        let messageConfig = TabItemConfigurationModel(
            title: "消息",
            normalImage: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill"),
            analyticsIdentifier: "tab_message",
            badgeValue: 5
        )
        
        let profileConfig = TabItemConfigurationModel(
            title: "我的",
            normalImage: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill"),
            analyticsIdentifier: "tab_profile"
        )
        
        // 3. Create Routes
        let routes = [
            TabRoute(configuration: homeConfig, viewController: UINavigationController(rootViewController: homeVC)),
            TabRoute(configuration: discoverConfig, viewController: UINavigationController(rootViewController: discoverVC)),
            TabRoute(configuration: messageConfig, viewController: UINavigationController(rootViewController: messageVC)),
            TabRoute(configuration: profileConfig, viewController: UINavigationController(rootViewController: profileVC))
        ]
        
        // 4. Initialize TabContainerController
        return TabContainerController(
            routes: routes,
            initialSelectedIndex: 0,
            tabBarStyle: .frostedGlass,
            selectionPolicy: { request in
                return .allow
            },
            selectionDidCommit: { request in
                print("Tab switched to index: \(request.toIndex)")
            }
        )
    }
    
    private static func createDemoViewController(title: String, color: UIColor) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = color
        vc.title = title
        return vc
    }
}
