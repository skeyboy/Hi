//
//  SKPackage.swift
//  Hello
//
//  Created by sk on 2018/10/8.
//

import Foundation
import FluentSQLite
import SQLite
import Vapor
/// 安装包简介
public struct SKPackage: SQLiteModel {
    public var id: Int?
    var userId: Int
    var createDate: TimeInterval
    var identifer: String
    
    /// 标记是那种资源包
    var type: Int
    init(userId: Int, identifer : String, type: Int) {
        self.userId = userId
        self.identifer = identifer
        self.createDate = Date().timeIntervalSince1970
        self.type = type
    }
}

extension SKPackage : Content&Migration&Parameter{}

// MARK: - 安装的真实安装资源列表
extension SKPackage{
    var packages:Children<SKPackage, SKInstallPackage>{
        return children(\.packageId)
    }
}

// MARK: - 安装包 逆推 创建者
extension SKPackage{
    var owner:Parent<SKPackage, SKUser>{
        return parent(\.userId)
    }
}
