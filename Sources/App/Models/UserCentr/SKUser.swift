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

