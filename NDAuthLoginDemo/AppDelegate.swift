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
        
        self._handle(openUrl: url)
        return true
    }
    
    //MARK: 支持所有iOS系统
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        self._handle(openUrl: url)
        return true
    }
    
    //MARK: iOS9之上
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        self._handle(openUrl: url)
        return true
    }
    
    /// 事件处理
    private func _handle(openUrl url: URL) -> Bool {
        
        // 解析参数
        let params = self.parseParamters(url: url)
        
        // 校验签名
        var originSign: String?
        
        var checkParams = Parameters()
        for (key, value) in params {
            
            if key == "sign" {
                // 获取旧的sign
                originSign = value
            }
            else {
                checkParams[key] = value
            }
        }
        
        guard let sign = originSign else {
            return false
        }
        
        // 构造签名
        let checkSign = self.buildSign(checkParams)
        
        // 校验签名
        guard checkSign == sign else {
            return false
        }
        
        // MARK: TODO 根据参数做对应处理
        
        
        return true
    }
    
    /// 解析url query参数
    func parseParamters(url: URL) -> [(String, String)] {
        
        let param = NDURLEncoding.decode(url)
        let urlEncoding = NDURLEncoding.init()
        
        return urlEncoding.queryComponents(param)
    }
    
    func buildSign(_ parameters: [String: Any]) -> String? {
        
        let urlEncoding = NDURLEncoding.init()
        // key字典序排序, 小写
        let sortedQuery = urlEncoding.query(parameters).lowercased()
        // 先进行base64，再进行md5
        return sortedQuery.nd_base64()?.nd_md5()
    }
}
