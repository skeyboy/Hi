//
//  SKTool.swift
//  Hello
//
//  Created by sk on 2018/10/8.
//

import Foundation
import Vapor

/// 根据请求 和 本地的IPA文件分析出安装信息
///
/// - Parameters:
///   - req: <#req description#>
///   - path: IPA文件路径
/// - Returns: <#return value description#>
/// - Throws: <#throws value description#>
public func ipaTool(req: Request, ipaPath path: String)throws -> EventLoopFuture<Dictionary<String, Any>>{
    //let path =  try req.sharedContainer.make(DirectoryConfig.self).workDir + "Public/s1538917708.271797.ipa"
    let currentTempDirFolder = NSTemporaryDirectory().appending(UUID.init().uuidString)
    
    
    let result = req.eventLoop.newPromise(Dictionary<String, Any>.self)
    
    let process: Process = Process.launchedProcess(launchPath: "/usr/bin/unzip"
        , arguments: ["-u", "-j", "-d", currentTempDirFolder, path, "Payload/*.app/embedded.mobileprovision", "Payload/*.app/Info.plist","*","-x", "*/*/*/*"])
    
    
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
                
                result.succeed(result: ["path":"\(currentTempDirFolder)".appending(bundleExecutable)+"\(appPropertyList)", "info": appPropertyList])
                
            }catch{
                result.fail(error: error)
            }
            
            
            //        result.succeed(result: "process succeeded\(currentTempDirFolder)")
            //        print("Task succeeded.\(currentTempDirFolder)")
        } else {
            result.succeed(result: [:])
            print("Task failed.")
        }
        
    }
    
    return result.futureResult
}

public func apkTool(req: Request, apkPath path: String)throws-> EventLoopFuture<String>{
    let result = req.eventLoop.newPromise(String.self)
    
    
    
    return result.futureResult
}
