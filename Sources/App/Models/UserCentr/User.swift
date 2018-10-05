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
    var createDate: Date = Date.init()
    var updateDate: Date = Date.init()
    var email: String
    var password:String?
    
    /// 默认会发邮件点击d链接完成确认
    var status: Int = SKUserStatus.unidentified.rawValue
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

