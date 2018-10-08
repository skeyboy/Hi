//
//  SKPackageScribePivot.swift
//  Hello
//
//  Created by sk on 2018/10/5.
//

import Foundation
import FluentSQLite
import Vapor
import SQLite


/// 用户订阅安装包更新通知
struct SKPackageScribePivot: SQLitePivot {
    static var leftIDKey: WritableKeyPath<SKPackageScribePivot, Int> = \.userId
    
    static var rightIDKey: WritableKeyPath<SKPackageScribePivot, Int> = \.packageId
    
    
    typealias Left = SKUser
    
    typealias Right = SKPackage
    
    var id: Int?
    var userId: Int
    var packageId: Int
    
}
extension SKPackageScribePivot :   Content & Migration {}

extension SKUser{
    var packages:Siblings<SKUser,SKPackage,SKPackageScribePivot>{
        return siblings()
    }
}



extension SKPackageScribePivot: ModifiablePivot{
    init(_ left: SKUser, _ right: SKPackage) throws {
        userId =  try left.requireID()
        packageId = try  right.requireID()
    }
}
