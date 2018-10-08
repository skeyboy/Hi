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
                                    if let package = package {
                                        //存在package 则installpackage直接入库
                                        let relaticePath = userFileRelativePath
                                        let skInstallpackage: SKInstallPackage =  SKInstallPackage.init(id: nil, userId: skUser.id!, packageId: package.id!, addDate: Date().timeIntervalSince1970, relativePath: relaticePath)
                                        
                                        return  skInstallpackage.create(on: req).flatMap({ (innInstallPackage) -> EventLoopFuture<String> in
                                            let result = req.eventLoop.newPromise(String.self)
                                            
                                            result.succeed(result:  "\(innInstallPackage.owner) \(innInstallPackage.package.child.owner) \(innInstallPackage)" )
                                            return result.futureResult
                                        })
                                        
                                    }else{//不存在 则先package信息入库，然后installpackage入库
                                       return SKPackage(userId: skUser.id!, identifer: identifer, type: upload.kind).create(on: req).flatMap({ (p) -> EventLoopFuture<String> in
                                            
                                        let skInstallpackage: SKInstallPackage =  SKInstallPackage.init(id: nil, userId: skUser.id!, packageId: p.id!, addDate: Date().timeIntervalSince1970, relativePath: path)
                                      return  skInstallpackage.create(on: req).flatMap({ (sInstallPackage) -> EventLoopFuture<String> in
                                        let result = req.eventLoop.newPromise(String.self)
                                        
                                            result.succeed(result:  "\(skInstallpackage.owner) \(skInstallpackage.package)")
                                        return result.futureResult
                                        })
                                        })
                                        
                                    }
                                })
                                //文件解析信息
//                                print(info)
//                                result.succeed(result: "\(info)")
//                                return result.futureResult
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
