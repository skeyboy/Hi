//
//  User.swift
//  Hello
//
//  Created by sk on 2018/10/4.
//

import Foundation
import FluentSQLite
import Vapor
import SQLite
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
struct SKUser: SQLiteModel {
    var id: Int?
    var name: String
    var createDate: TimeInterval?
    var updateDate: TimeInterval? 
    var email: String
    var password:String
    
    /// 默认会发邮件点击d链接完成确认
    var status: Int? = SKUserStatus.unidentified.rawValue
    init(name: String, email: String, password: String) {
        self.name = name
        
        self.email = try! MD5.hash(email).base64EncodedString()
        self.password = try! MD5.hash(password).base64EncodedString()
        self.createDate = Date().timeIntervalSince1970
        self.updateDate = self.createDate
    }
}
extension SKUser: All{
    static var defaultContentType: MediaType {
        return .json
    }

}


struct SKRegistVerfiy: SQLiteModel {
    var id: Int?
    var email: String =  VerfiyCodeRender.renderInstance.default
    var verfiyCode: String
    var create: TimeInterval = Date().timeIntervalSince1970
    var expri: Double = 60 * 60 * 24
}
extension SKRegistVerfiy{
    var isCodeAvailable: Bool{
        return Date().timeIntervalSince1970 - create <= expri
    }
}

extension SKRegistVerfiy: All{}





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

