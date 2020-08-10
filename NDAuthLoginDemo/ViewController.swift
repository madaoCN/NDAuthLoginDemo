//
//  ViewController.swift
//  NDAuthLoginDemo
//
//  Created by 梁宪松 on 2020/8/7.
//  Copyright © 2020 madao. All rights reserved.
//

import UIKit
import CommonCrypto

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /// 认证登录请求事件
    @IBAction func handlerAuthLoginAction(_ sender: Any) {
        
        // 平台申请的应用id
        let appId = "aq20200807"
        // bundleId md5值
        let appSign = "com.madao.NDAuthLoginDemo".nd_md5()
        // 时间戳
        let ts = Int(Date.init().timeIntervalSince1970)
        // 请求参数
        var params: [String : Any] = ["appId": appId, "appSign": appSign, "timestamp": ts]
        // 构造请求url
        let url = "nd.aqcenter://oncetoken/auth"
        guard let requestURL = URL.init(string: url) else {
            return
        }
        // 构造签名
        let sign = self.buildSign(params)
        // 添加签名
        params["sign"] = sign ?? ""
        // 重新构造url
        let urlEncoding = NDURLEncoding.init()
        let encodedURL = urlEncoding.encode(requestURL, with: params)
        // 拉起应用
        UIApplication.shared.openURL(encodedURL)
    }
    
    func buildSign(_ parameters: [String: Any]) -> String? {
        
        let urlEncoding = NDURLEncoding.init()
        // key字典序排序, 小写
        let sortedQuery = urlEncoding.query(parameters).lowercased()
        // 先进行base64，再进行md5
        return sortedQuery.nd_base64()?.nd_md5()
    }
}

extension String {
    
    func nd_md5() -> String {
        
        let ccharArray = self.cString(using: String.Encoding.utf8)
        var uint8Array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(ccharArray, CC_LONG(ccharArray!.count - 1), &uint8Array)
        return uint8Array.reduce("") { $0 + String(format: "%02X", $1) }.lowercased()
    }
    
    func nd_base64() -> String? {
        
        return self.data(using: String.Encoding.utf8)?.base64EncodedString()
    }
}
