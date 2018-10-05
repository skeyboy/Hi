//
//  MobileAPp.swift
//  Hello
//
//  Created by sk on 2018/9/30.
//

import FluentSQLite
import Vapor
enum AppType: String {
    case iOS = "iOS"
    case android = "android"
    case other = "other"
}
extension AppType:Codable{}

 struct MobileApp: SQLiteModel {
    static let name = "MobileApp"
    static let entity = "MobileApp"

    var id: Int?
    var identifier: String
    var version: String
    var type: AppType = .iOS
    init(id: Int? = nil, identifier: String, version: String, type: AppType = .iOS) {
        self.id = id
        self.identifier = identifier
        self.version = version
        self.type = type
    }
}
 struct History: SQLiteModel {
    static let name = "History"
    static let entity = "History"
    
    var id: Int?
    var  date: Date = Date()
    var fileName: String
    init(id: Int? = nil,  name fileName:String) {
        self.id = id
        self.fileName = fileName
    }
}

 struct MobileAppHistory: SQLitePivot{
    
    static var leftIDKey: WritableKeyPath<MobileAppHistory, Int> = \.appId
    
    static var rightIDKey: WritableKeyPath<MobileAppHistory, Int> = \.historyId
    
    
    typealias Left = MobileApp
    
    typealias Right = History
    
    var id: Int?
    var appId: Int
    var historyId: Int
    
    
}

extension MobileAppHistory: ModifiablePivot{
    init(_ left: MobileApp, _ right: History) throws {
        appId = try left.requireID()
        historyId = try right.requireID()
    }
    
    
}

extension History: All{}
extension MobileAppHistory: All{}
extension MobileApp: All{}
