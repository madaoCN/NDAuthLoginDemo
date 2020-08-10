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
    
        return self._handle(openUrl: url)
    }
    
    //MARK: 支持所有iOS系统
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        return self._handle(openUrl: url)
    }
    
    //MARK: iOS9之上
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return self._handle(openUrl: url)
    }
    
    /// 事件处理
    /// 示例数据： aq20200807://oauth?errCode=-1&onceCode=1111111111111111111&sign=daf78c74332d1b3fee6f02f953a38dab&timestamp=1597045&type=1000
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
        
        // 获取type
        let type = checkParams["type"] as? String
        // 获取errcode
        let errCode = checkParams["errCode"] as? String
        // 获取oncecode
        let onceCode = checkParams["onceCode"] as? String
        
        // 登录类型
        if type == "1000" {
            
            var alert: UIAlertController!

            // 判断 errCode
            switch errCode {
            case "-1":
                // 返回一次性登录token
                alert = UIAlertController(title: "提示", message: "获取token成功：\(onceCode ?? "")", preferredStyle: .alert)
                break
            case "1100":
                // 用户拒绝
                alert = UIAlertController(title: "提示", message: "用户拒绝了授权", preferredStyle: .alert)
                break
            case "1200":
                // 用户取消
                alert = UIAlertController(title: "提示", message: "用户取消了授权", preferredStyle: .alert)
                break
            case "1300":
                // 获取token失败
                alert = UIAlertController(title: "提示", message: "获取token失败", preferredStyle: .alert)
                break
            default:
                alert = UIAlertController(title: "提示", message: "未知错误", preferredStyle: .alert)
                break
            }
            
            alert?.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: { _ in
            }))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        return true
    }
    
    /// 解析url query参数
    func parseParamters(url: URL) -> [(String, String)] {
        
        let param = NDURLEncoding.decode(url)
        let urlEncoding = NDURLEncoding.init()
        
        return urlEncoding.queryComponents(param)
    }
    
    func buildSign(_ parameters: [String: Any]) -> String? {
        
        var str = ""
        str += "errCode=\(parameters["errCode"] ?? "")&"
        str += "onceCode=\(parameters["onceCode"] ?? "")&"
        str += "timestamp=\(parameters["timestamp"] ?? "")&"
        str += "type=\(parameters["type"] ?? "")"
        
        // 先进行base64，再进行md5
        return str.nd_base64()?.nd_md5()
    }
}
