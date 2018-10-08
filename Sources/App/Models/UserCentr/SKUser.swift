//
//  SKUser.swift
//  Hello
//
//  Created by sk on 2018/10/8.
//


import Foundation
import FluentSQLite
import Vapor
import SQLite
import Crypto





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


// MARK: - 查找创建的安装包信息者
extension SKUser{
    var package:Children<SKUser, SKPackage>{
        return children(\.userId)
    }
    
    
}


// MARK: - 用户上传的安装包文件
extension SKUser{
    var installPackages:Children<SKUser,SKInstallPackage>{
        return children(\.userId)
    }
}
