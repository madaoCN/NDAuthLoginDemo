//
//  AppDelegate.swift
//  NDAuthLoginDemo
//
//  Created by 梁宪松 on 2020/8/7.
//  Copyright © 2020 madao. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}



extension AppDelegate {
    
    //MARK: 支持所有iOS系统
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return true
    }
    
    //MARK: 支持所有iOS系统
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        return true
    }
    
    //MARK: iOS9之上
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return true
    }
}
