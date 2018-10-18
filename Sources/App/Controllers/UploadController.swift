//
//  UploadController.swift
//  Hello
//
//  Created by sk on 2018/10/8.
//

import Foundation
import Vapor
import SQLite
import DatabaseKit
import SwiftSMTP
import FluentSQLite
import Crypto
class SKUploadController {
    func boot(router: Router) throws {
//        router.post(Upload.self
//            , at: "upload"
//            , use: upload)
    }
    /// 根据局用户邮箱来上传安装包
    ///
    /// - Parameter req: <#req description#>
    /// - Returns: <#return value description#>
    public func upload( req: Request) -> EventLoopFuture<String>{
        
        do{
            
            return try req.content.decode(Upload.self).flatMap { (u) -> EventLoopFuture<String> in
                let upload: Upload = u
                //            let upload: Upload = try req.query.decode(Upload.self)
                
                return SKUser.query(on: req).filter(\.email
                    , .equal
                    , upload.email).first().flatMap({ (skUser) -> EventLoopFuture<String> in
                        
                        if let skUser = skUser {
                            
                            let path =  try! req.sharedContainer.make(DirectoryConfig.self).workDir + "Public/"
                            let userFolder = u.email
                            do{
                                let fileManager = FileManager.default
                                if !fileManager.fileExists(atPath: path+userFolder) {
                                    try fileManager.createDirectory(atPath: path+userFolder
                                        , withIntermediateDirectories: true
                                        , attributes: [:])
                                }
                                let userFileRelativePath = userFolder + "/\(Date().timeIntervalSince1970)" +  u.kind.type
                                let  filePath = path + userFileRelativePath
                                
                                try upload.file.write(to: URL(fileURLWithPath: filePath))
                                return  try ipaTool(req: req, ipaPath: filePath).flatMap({ (info) -> EventLoopFuture<String> in
                                    let identifer =  (info["info"] as! Dictionary<String, Any>)["CFBundleIdentifier"] as! String
                                    return   SKPackage.query(on: req).filter(\.identifer, .equal, identifer).first().flatMap({ (package) -> EventLoopFuture<String> in
                                        let relativePath = userFileRelativePath //相对与系统的Public的相对路径

                                        if let package = package {
                                            //存在package 则installpackage直接入库
                                            let skInstallpackage: SKInstallPackage =  SKInstallPackage.init(id: nil, userId: skUser.id!, packageId: package.id!, addDate: Date().timeIntervalSince1970, relativePath: relativePath)
                                            
                                            return  skInstallpackage.create(on: req).flatMap({ (innInstallPackage) -> EventLoopFuture<String> in
                                               
                                                return innInstallPackage.package.get(on: req).flatMap({ (sk:SKPackage) -> EventLoopFuture<String> in
                                                    return try self.uploadResult(req: req, sk: sk)
                                              
                                                })
                                                
//                                                let result = req.eventLoop.newPromise(String.self)
//
//                                                result.succeed(result:  "\(innInstallPackage.owner) \(innInstallPackage.package.child.owner) \(innInstallPackage)" )
//                                                return result.futureResult
                                            })
                                            
                                        }else{//不存在 则先package信息入库，然后installpackage入库
                                            return SKPackage(userId: skUser.id!, identifer: identifer, type: upload.kind).create(on: req).flatMap({ (p) -> EventLoopFuture<String> in
                                                
                                                let skInstallpackage: SKInstallPackage =  SKInstallPackage.init(id: nil, userId: skUser.id!, packageId: p.id!, addDate: Date().timeIntervalSince1970, relativePath: relativePath)
                                                return  skInstallpackage.create(on: req).flatMap({ (sInstallPackage) -> EventLoopFuture<String> in
                                                    return sInstallPackage.package.get(on: req).flatMap({ (sk:SKPackage) -> EventLoopFuture<String> in
                                                        return try self.uploadResult(req: req, sk: sk)
                                                    })
                                                    
//                                                    let result = req.eventLoop.newPromise(String.self)
//
//                                                    result.succeed(result:  "\(skInstallpackage.owner) \(skInstallpackage.package)")
//                                                    return result.futureResult
                                                })
                                            })
                                            
                                        }
                                    })
                                
                                })
                            } catch{
                                let result = req.eventLoop.newPromise(String.self)
                                
                                result.fail(error: error)
                            }
                            
                        }else{
                            let result = req.eventLoop.newPromise(String.self)
                            result.succeed(result: "用户" + upload.email + "不存在")
                            return result.futureResult
                        }
                        let result = req.eventLoop.newPromise(String.self)
                        result.succeed(result: "这里是不走的地方")
                        return result.futureResult
                        
                    })
            }
        }catch{
            let result = req.eventLoop.newPromise(String.self)
            result.fail(error: error)
            return result.futureResult
        }
    }
    
   
    
    func uploadResult(req: Request, sk:SKPackage)throws -> EventLoopFuture<String> {
        return   try  sk.users.query(on: req).all().flatMap({ (us) -> EventLoopFuture<String> in
            let result = req.eventLoop.newPromise(String.self)
            
            if us.isEmpty {//没有订阅者
                result.succeed(result: "上传完成")
                
                
            }else{//发送订阅者
                
                let toSubscribes: [Mail.User] =  us.map({ (u) -> Mail.User in

                    return Mail.User.init(name: u.name, email: u.email)
                })
                 SKMialTool.mail(to: toSubscribes, subject: "App更新提示", text: "您关注的App已经发布更新", attachments: [], completion: { (error) in
                    if let error = error {
                        result.fail(error: error)
                    }else{
                        result.succeed(result: "已经发送给订阅者")
                    }
                })
                
//                let smtp: SMTP = SMTP.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
//                let fromUser =  Mail.User(name: "注册码确认邮件", email: "lylapp@163.com")
//
//                let mail = Mail(from: fromUser
//                    , to: toSubscribes
//                    , cc: [], bcc: []
//                    , subject: "欢迎®️"
//                    , text: "您关注的App更新了点击查看"
//                    , attachments: []
//                    , additionalHeaders: [:])
//
//                smtp.send(mail, completion: { (error) in
//                    print(error as Any)
//                    if let error = error {
//                        result.fail(error: error)
//                    }else{
//                        result.succeed(result: "已经发送给订阅者")
//                    }
//                })
                
            }
            return result.futureResult
        })
        
    }
}

extension String{
    public var type: String{
        switch self {
        case "0":
            return ".ip"
        default:
            return ".ipa"
        }
    }
}
struct Upload : Content {
    
    var file: Data
    var kind : Int
    var email: String
    static var defaultContentType: MediaType  = .formData
}
