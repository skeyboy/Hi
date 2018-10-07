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
extension Process{
    @objc  func binary( binaryPath: String){
        let newProcess = Process.launchedProcess(launchPath: "/usr/bin/codesign"
            , arguments:  ["-d", binaryPath, "--entitlements", ":-"] )
        let pip = Pipe.init()
        newProcess.standardOutput = pip
        newProcess.terminationHandler = { t in
            if t.terminationStatus == 0 {
                let codesignEntitlementsData =   (t.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
                let entitlementsPropertyList:Dictionary<String, Any> =         try! PropertyListSerialization.propertyList(from: codesignEntitlementsData
                    , options:
                    PropertyListSerialization.ReadOptions.mutableContainers
                    , format: nil) as! Dictionary<String, Any>
                
            }
        }
        
        if #available(OSX 10.13, *) {
            try! newProcess.run()
        } else {
            // Fallback on earlier versions
        }
        
    }
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
    var status: Int? = SKUserStatus.ok.rawValue
    public   init(name: String, email: String, password: String) {
        self.name = name
        
        self.email = email
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
    func binary( binaryPath: String){
        let newProcess = Process.launchedProcess(launchPath: "/usr/bin/codesign"
            , arguments:  ["-d", binaryPath, "--entitlements", ":-"] )
        let pip = Pipe.init()
        newProcess.standardOutput = pip
        newProcess.terminationHandler = { t in
            if t.terminationStatus == 0 {
                let codesignEntitlementsData =   (t.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
                let entitlementsPropertyList:Dictionary<String, Any> =         try! PropertyListSerialization.propertyList(from: codesignEntitlementsData
                    , options:
                    PropertyListSerialization.ReadOptions.mutableContainers
                    , format: nil) as! Dictionary<String, Any>
                
            }
        }
        
        if #available(OSX 10.13, *) {
            try! newProcess.run()
        } else {
            // Fallback on earlier versions
        }
        
    }
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
                
                //首先判断是否存在 邮箱&验证码
                if sks.isEmpty {
                    let result = req.eventLoop.newPromise(String.self)
                    result.succeed(result: "邮箱和验证码不存在")
                    return result.futureResult
                }
                //判断验证码是否在有效期内
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
                    //查询邮箱是否被注册过
                    or.filter(\.email, SQLiteBinaryOperator.equal, skUser.email)
                }).all().flatMap({ (us) -> EventLoopFuture<String> in
                    
                    if us.isEmpty {//没有注册 则开始注册
                        return
                            skUser.save(on: req).flatMap(to: String.self, { (u) -> EventLoopFuture<String> in
                                let result = req.eventLoop.newPromise(String.self)
                                result.succeed(result: "\(u)")
                                return result.futureResult
                            })
                    }else{
                        //已经被注册提示已经注册
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
    
 
    
    public func package(req:Request)throws-> EventLoopFuture<String>{
        let path =  try req.sharedContainer.make(DirectoryConfig.self).workDir + "Public/s1538917708.271797.ipa"
        let currentTempDirFolder = NSTemporaryDirectory().appending(UUID.init().uuidString)
        
        
        let result = req.eventLoop.newPromise(String.self)
        
        let process: Process = Process.launchedProcess(launchPath: "/usr/bin/unzip"
            , arguments: ["-u", "-j", "-d", currentTempDirFolder, path, "Payload/*.app/embedded.mobileprovision", "Payload/*.app/Info.plist","*","-x", "*/*/*/*"])
        
//        let pip = Pipe()
//        process.standardOutput = pip
//        pip.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
//        pip.fileHandleForWriting.waitForDataInBackgroundAndNotify()
        process.terminationHandler = {p in
            let status = p.terminationStatus
            
            if status == 0 {
                
                var provisionPath: String  = "\(currentTempDirFolder)".appending("/embedded.mobileprovision")
                
                let plistPath: String = "\(currentTempDirFolder)".appending("/Info.plist")
                do{
                    let appPlist = try! Data.init(contentsOf: URL(fileURLWithPath: plistPath))
                    let  appPropertyList: Dictionary<String,Any> = try PropertyListSerialization.propertyList(from: appPlist
                        , options: PropertyListSerialization.ReadOptions.mutableContainers
                        , format: nil) as! Dictionary
                    
                    let bundleExecutable = appPropertyList["CFBundleExecutable"] as! String
                    
                    let binaryPath = "\(currentTempDirFolder)/\(bundleExecutable)"
                    if process.terminationReason == .exit{
                        print("结束🔚")
                    }
//                    var value: Unmanaged<AnyObject> =       process.perform(#selector(process.binary(binaryPath:)), with: binaryPath)
                    
                    //                    if p.terminationReason == .exit  {
                    //                        if p.isRunning{
                    //                            p.terminate()
                    //
                    //                        }
                    //                    let newProcess = Process.launchedProcess(launchPath: "/usr/bin/codesign"
                    //                        , arguments:  ["-d", binaryPath, "--entitlements", ":-"] )
                    //                    let pip = Pipe.init()
                    //                    newProcess.standardOutput = pip
                    //                    newProcess.terminationHandler = { t in
                    //                        if t.terminationStatus == 0 {
                    //                         let codesignEntitlementsData =   (t.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
                    //                         let entitlementsPropertyList:Dictionary<String, Any> =         try! PropertyListSerialization.propertyList(from: codesignEntitlementsData
                    //                                , options:
                    //                          PropertyListSerialization.ReadOptions.mutableContainers
                    //                            , format: nil) as! Dictionary<String, Any>
                    //
                    //                        }
                    //                    }
                    //
                    //                    if #available(OSX 10.13, *) {
                    //                        try! newProcess.run()
                    //                    } else {
                    //                        // Fallback on earlier versions
                    //                        }
                    //
                    //                    }
                    
                    
                    result.succeed(result: "\(currentTempDirFolder)".appending(bundleExecutable)+"\(appPropertyList)")
                    
                }catch{
                    result.fail(error: error)
                }
                
                
                result.succeed(result: "process succeeded\(currentTempDirFolder)")
                print("Task succeeded.\(currentTempDirFolder)")
            } else {
                result.succeed(result: "process failed")
                print("Task failed.")
            }
        }
        
        do{
            
            if #available(OSX 10.13, *) {
                try process.run()
            } else {
                // Fallback on earlier versions
                result.succeed(result: "服务系统版本低不支持")
            }
        }catch{
            print(error)
            //            result.fail(error: error)
        }
        //        process.waitUntilExit()
        //        while process.terminationStatus != 0 {
        //
        //        }
        return result.futureResult
    }
        public func login(req: Request)throws-> EventLoopFuture<String>{
        struct InnerUser: Content{
            var email: String
            var password: String
        }
        
        let user = try! req.query.decode(InnerUser.self)
     return   SKUser.query(on: req).group(SQLiteBinaryOperator.or) { (or) in
            or.filter(\.email, SQLiteBinaryOperator.equal, user.email)
            }.all().flatMap { (us) -> EventLoopFuture<String> in
                let result = req.eventLoop.newPromise(String.self)

                if us.isEmpty {
                    result.succeed(result: "用户不存在")
                    return result.futureResult
                }else{
                    
                    if us.first!.password.elementsEqual(user.password.md5Base64) {
                        
                        result.succeed(result: "登陆成功:\(us.first!)")
                    }else{
                        result.succeed(result: "密码错误")
                    }
                    return result.futureResult
                }
        }
        
    }
    
}


struct SKResponse<T> : Content where T: Content {
    var data: T
    var status: Int
    var message: String
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




