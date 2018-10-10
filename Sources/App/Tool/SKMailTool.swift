//
//  SKMailTool.swift
//  Hello
//
//  Created by sk on 2018/10/10.
//

import Foundation
import SwiftSMTP
import Vapor

public class SKMialConfig{
    public  var smtp: SMTP?
    public var fromUser: Mail.User?
    private init(){}
    private  static var config:SKMialConfig = SKMialConfig()
    static var `default`: SKMialConfig{
        config.smtp =  SMTP.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
        config.fromUser = Mail.User(name: "注册码确认邮件", email: "lylapp@163.com")
        return  config
    }
    func send(_ mail:Mail,completion:@escaping (Error?)->Void) -> Void {
        smtp?.send(mail, completion: completion)
    }
}
public class SKMialTool{
    
    public static func mail(
                            to: [Mail.User],
                            subject: String = "",
                            text: String = "",
                            attachments: [Attachment] = [],
                             completion:@escaping (Error?)->Void) -> Void {
        mail(from: SKMialConfig.default.fromUser, to: to, cc: [], bcc: [], subject: subject, text: text, attachments: [], additionalHeaders: [:], completion: completion)
    }
   public static func mail(from: Mail.User?,
              to: [Mail.User],
              cc: [Mail.User] = [],
              bcc: [Mail.User] = [],
              subject: String = "",
              text: String = "",
              attachments: [Attachment] = [],
              additionalHeaders: [String: String] = [:], completion:@escaping (Error?)->Void) -> Void {
        let fromUser = from ?? SKMialConfig.default.fromUser!
        let mail = Mail(from: fromUser
            , to: to
            , cc: [], bcc: []
            , subject: subject
            , text: text
            , attachments: []
            , additionalHeaders: [:])
    SKMialConfig.default.send( mail, completion: completion)
    }
    public static func mail(mail:Mail,completion:@escaping (Error?)->Void)->Void{
        SKMialConfig.default.send( mail, completion: completion)
    }
}
