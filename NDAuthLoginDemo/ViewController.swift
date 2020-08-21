//
//  ViewController.swift
//  NDAuthLoginDemo
//
//  Created by 梁宪松 on 2020/8/7.
//  Copyright © 2020 madao. All rights reserved.
//

import UIKit
import CommonCrypto

extension Notification.Name {
    
    public static let RECEIVED_TOKEN = NSNotification.Name("RECEIVED_TOKEN")
}

class ViewController: UIViewController {
    
    // 平台申请的应用id
    let appId = "ios20200819"
    // bundleId md5值
    let appSign = "com.madao.NDAuthLoginDemo".nd_md5()
    
    @IBOutlet weak var tokenLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(forName: .RECEIVED_TOKEN, object: nil, queue: nil) {[weak self] (notification) in
            
            if let code = notification.object as? String {
                
                // 跳转修改密码页面
                self?.tokenLabel.text = code
            }
        }
    }
    
    /// 认证登录请求事件
    @IBAction func handlerAuthLoginAction(_ sender: Any) {
        

        // 时间戳
        let ts = Int(Date.init().timeIntervalSince1970)
        // 请求参数
        var params: [String : Any] = ["appId": appId, "appSign": appSign, "timestamp": ts]
        // 构造请求url
        let url = "nd.aqcenter://www.99aq.com/oncetoken/auth"
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
    
    
    /// 认证token
    @IBAction func verifyToken(_ sender: Any) {
        
        guard let token = self.tokenLabel.text else {
            return
        }
        
        guard let requestURL = URL.init(string: "https://regapi.testreg.99.com/app/ThirdCheckCode.aspx?code=\(token)&clientid=\(appId)") else {
            return
        }
        
        let uploadRequest = URLRequest.init(url: requestURL)
        URLSession.shared.dataTask(with: uploadRequest) {[weak self] (data, response, error) in
            
            
            guard error == nil else {
                
                // 发生了错误
                print("verify error")
                
                let alert = UIAlertController(title: "提示", message: "认证失败", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print("Status code error \n")
                    
                    let alert = UIAlertController(title: "提示", message: "认证请求返回状态码不正确", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                    return
            }
            
            guard let dt = data,
                let jsonString = String.init(data: dt, encoding: .utf8) else {
                    
                    print("parse data error")
                    
                    let alert = UIAlertController(title: "提示", message: "认证请求返回数据不正确", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                    return
            }
            print("verify success")
            print(jsonString)
            
            
            let alert = UIAlertController(title: "提示", message: "认证成功：\(jsonString)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
            
        }.resume()
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
