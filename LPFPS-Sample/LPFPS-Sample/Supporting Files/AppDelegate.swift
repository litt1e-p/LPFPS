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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = TabBarOneController()
        window?.makeKeyAndVisible()
        appFPSInit()
        return true
    }
    
    private func appFPSInit() {
        let kFPSIns = LPFPS.sharedFPS
        #if DEBUG
            kFPSIns.start()
        #else
            kFPSIns.stop()
        #endif
    }
}

