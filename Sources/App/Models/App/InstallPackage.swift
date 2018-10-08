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

//
///// 真实的每个安装包
//struct SKInstallPackage: SQLiteModel {
//    var id: Int?
//    
//    /// 安装文件的上传者
//    var userId: Int
//    var packageId: Int
//    var addDate: Date = Date.init()
//    var relativePath: String
//}
//
//
//
//// MARK: - 通过安装包逆推安装包的简介
//extension SKInstallPackage{
//    var package:Parent<SKInstallPackage, SKPackage>{
//        return parent(\.packageId)
//    }
//}
//
//
//
//// MARK: - 安装包文件逆推出上传者
//extension SKInstallPackage{
//    var owner: Parent<SKInstallPackage, SKUser>{
//        return parent(\.userId)
//    }
//}
//
