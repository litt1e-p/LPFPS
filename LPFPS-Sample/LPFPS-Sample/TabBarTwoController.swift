//
//  TabBarTwoController.swift
//  LPFPS-Sample
//
//  Created by litt1e-p on 16/7/8.
//  Copyright © 2016年 litt1e-p. All rights reserved.
//

import UIKit

class TabBarTwoController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .orange
        let twoVc = TwoViewController()
        twoVc.tabBarItem.title = "One"
        twoVc.view.backgroundColor = .orange
        viewControllers = [UINavigationController(rootViewController: twoVc)]
    }

}
