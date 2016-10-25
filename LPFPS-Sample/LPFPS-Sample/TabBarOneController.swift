//
//  TabBarOneController.swift
//  LPFPS-Sample
//
//  Created by litt1e-p on 16/7/8.
//  Copyright © 2016年 litt1e-p. All rights reserved.
//

import UIKit

class TabBarOneController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .purple
        let oneVc = OneViewController()
        oneVc.tabBarItem.title = "One"
        oneVc.view.backgroundColor = .purple
        viewControllers = [UINavigationController(rootViewController: oneVc)]
    }
}
