//
//  UserController.swift
//  Hello
//
//  Created by sk on 2018/10/5.
//

import Foundation
import Vapor
import SQLite
import DatabaseKit
import SwiftSMTP
import FluentSQLite
import Crypto


/// 会员的状态
///
/// - ok: 正常
/// - forget: 忘记密码
/// - suspend: 因为某些原因暂停
/// - unidentified: 注册但是没有认证，等待确认
enum SKUserStatus: Int{
    case ok = 0
    case forget = 1
    case suspend = 2
    case unidentified = 3
}


/// SK的用户数据模型
public struct SKUser: SQLiteModel {
    public  var id: Int?
    var name: String
    var createDate: TimeInterval?
    var updateDate: TimeInterval?
    var email: String
    var password:String
    
    /// 默认会发邮件点击d链接完成确认
    var status: Int? = SKUserStatus.unidentified.rawValue
    public   init(name: String, email: String, password: String) {
        self.name = name
        
        self.email = try! MD5.hash(email).base64EncodedString()
        self.password = try! MD5.hash(password).base64EncodedString()
        self.createDate = Date().timeIntervalSince1970
        self.updateDate = self.createDate
    }
}
extension SKUser: Migration&Content&Parameter {
    public static var defaultContentType: MediaType {
        return .json
    }
    
}
extension String{
    var md5Base64: String{
        return try! MD5.hash(self).base64EncodedString()
    }
}

final class SKUserController {
    public func regist(req: Request)throws-> EventLoopFuture<String>{
        
        struct InnerUser : Content {
            var name:String
            var code: String
            var email: String
            var password: String
        }
        
        let innerUser : InnerUser = try req.query.decode(InnerUser.self)
        
        return   SKRegistVerfiy.query(on: req)
            .group(SQLiteBinaryOperator.and, closure: { (and) in
                and.filter(\.verfiyCode, .equal, innerUser.code)
                and.filter(\.email, .equal, innerUser.email)
            }).all()
            .flatMap({ (sks) -> EventLoopFuture<String> in
                
                
                if sks.isEmpty {
                    let result = req.eventLoop.newPromise(String.self)
                    result.succeed(result: "邮箱和验证码不存在")
                    return result.futureResult
                }
                for sk in sks {
                    if !sk.isCodeAvailable {
                        let result = req.eventLoop.newPromise(String.self)

                        result.succeed(result: "验证码过期")

                        return result.futureResult
                    }

                }
                let innerUser : InnerUser = try req.query.decode(InnerUser.self)
                
                let skUser: SKUser = SKUser.init(name: innerUser.name
                    , email: innerUser.email
                    , password: innerUser.password)
                
                return  SKUser.query(on: req).group(SQLiteBinaryOperator.or, closure: { (or) in
                    or.filter(\.email, SQLiteBinaryOperator.equal, skUser.email)
                }).all().flatMap({ (us) -> EventLoopFuture<String> in
                        if us.isEmpty {
                            return
                                skUser.save(on: req).flatMap(to: String.self, { (u) -> EventLoopFuture<String> in
                                    let result = req.eventLoop.newPromise(String.self)
                                    result.succeed(result: "\(u)")
                                    return result.futureResult
                                })
                        }else{
                            let e = req.eventLoop.newPromise(String.self)
                            e.succeed(result: "用户已存在")
                            return e.futureResult
                            
                        }
                    })
                
                
            })
        
        
    }
    public func sendCode(req: Request) throws-> EventLoopFuture<String> {
        struct Email: Content {
            var email: String
        }
        let email: Email = try req.query.decode(Email.self)
        
        return    SKRegistVerfiy.query(on: req).filter(\.email, .equal, email.email).first().flatMap({ (verfiy) -> EventLoopFuture<String> in
            
            
            if let v = verfiy {//已经存在
                let result = req.eventLoop.newPromise(String.self)
                
                result.succeed(result: v.emailExistMessage)
                return result.futureResult
                
            }else{
                
                let reg =  SKRegistVerfiy.init(email: email.email)
                return  reg.save(on: req).flatMap({ (skVer) -> EventLoopFuture<String> in
                    
                    let smtp: SMTP = SMTP.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
                    let fromUser =  Mail.User(name: "注册码确认邮件", email: "lylapp@163.com")
                    let email = skVer.email
                    let toUser = Mail.User.init(email: email)
                    
                    let mail = Mail(from: fromUser
                        , to: [toUser]
                        , cc: [], bcc: []
                        , subject: "欢迎®️"
                        , text: skVer.message
                        , attachments: []
                        , additionalHeaders: [:])
                    let result = req.eventLoop.newPromise(String.self)
                    
                    smtp.send(mail, completion: { (error) in
                        print(error as Any)
                        if let error = error {
                            result.fail(error: error)
                        }else{
                            result.succeed(result: skVer.message)
                        }
                    })
                    return result.futureResult
                })
            }
        })
    }
    
}


public class VerfiyCodeRender{
    
    private init() {
        
    }
    public static let renderInstance = VerfiyCodeRender()
    public func generateVerfiyCode(_ seed:String = "1234567890", codeLenght maxLength: Int = 6)-> String{
        var verfiyCode = ""
        for _ in 0 ... ( (maxLength > seed.count ? seed.count : maxLength) - 1 ) {
            let index =     arc4random_uniform(UInt32(maxLength))
            verfiyCode.append( seed[seed.index(seed.startIndex, offsetBy: index)])
        }
        return verfiyCode
    }
    var  `default`: String{
        return generateVerfiyCode()
    }
    
}



struct SKRegistVerfiy: SQLiteModel {
    public var id: Int?
    var email: String
    var verfiyCode: String =  VerfiyCodeRender.renderInstance.default
    var create: TimeInterval = Date().timeIntervalSince1970 * 1000
    var expri: Double = 60 * 60 * 24
}
extension SKRegistVerfiy{
    
    /// 邮箱验证入库
    ///
    /// - Parameters:
    ///   - email: 接受验证码的邮箱
    ///   - code: 随机验证码 默认6位数字
    ///   - expri: 有效期默认1天
    init(email: String, verfiyCode code:String = VerfiyCodeRender.renderInstance.default, expri: Double = 24 * 60 * 60){
        let time = Date().timeIntervalSince1970 * 1000
        self.init(id: nil,
                  email: email,
                  verfiyCode: code,
                  create: time,
                  expri: expri)
    }
}
extension SKRegistVerfiy{
    var isCodeAvailable: Bool{
        return Date().timeIntervalSince1970 * 1000 - create <= expri * 1000
    }
    
    var message:String{
        return "您的确认码已经发到：\(self.email) 确认码是:\(verfiyCode) 将在\(expri/(24*60*60))天过期"
    }
    var emailExistMessage: String{
        return "您邮箱：\(email)已经注册，因此您不能重复用于注册"
    }
    
}
//typealias All = Migration&Content&Parameter

extension SKRegistVerfiy: Migration&Content&Parameter {
    
}




