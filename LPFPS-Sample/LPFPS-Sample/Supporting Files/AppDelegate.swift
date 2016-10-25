//
//  AppDelegate.swift
//  LPFPS-Sample
//
//  Created by litt1e-p on 16/7/8.
//  Copyright © 2016年 litt1e-p. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TabBarOneController()
        window?.makeKeyAndVisible()
        appFPSInit()
        return true
    }
    
    fileprivate func appFPSInit() {
        let kFPSIns = LPFPS.sharedFPS
        #if DEBUG
            kFPSIns.start()
        #else
            kFPSIns.stop()
        #endif
    }
}

