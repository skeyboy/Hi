//
//  InstallPackage.swift
//  Hello
//
//  Created by sk on 2018/10/4.
//

import Foundation
import FluentSQLite
import Vapor
import SQLite


/// 真实的每个安装包
struct SKInstallPackage: SQLiteModel {
    var id: Int?
    
    /// 安装文件的上传者
    var userId: Int
    var packageId: Int
    var addDate: Date = Date.init()
    var relativePath: String
}



/// 安装包简介
struct SKPackage: SQLiteModel {
    var id: Int?
    var userId: Int
    var createDate: Date = Date.init()
}

// MARK: - 安装的真实安装资源列表
extension SKPackage{
    var packages:Children<SKPackage, SKInstallPackage>{
        return children(\.packageId)
    }
}

// MARK: - 通过安装包逆推安装包的简介
extension SKInstallPackage{
    var package:Parent<SKInstallPackage, SKPackage>{
        return parent(\.packageId)
    }
}


// MARK: - 安装包 逆推 创建者
extension SKPackage{
    var owner:Parent<SKPackage, SKUser>{
        return parent(\.userId)
    }
}

// MARK: - 安装包文件逆推出上传者
extension SKInstallPackage{
    var owner: Parent<SKInstallPackage, SKUser>{
        return parent(\.userId)
    }
}

