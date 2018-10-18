//
//  Topic.swift
//  Hello
//
//  Created by sk on 2018/10/17.
//

import Foundation
import FluentSQLite
import Vapor
import SQLite

/// 每条评论都有一个类型用于区分评论的用途
///
/// - topic: 评论是关于主题发布的
/// - user: 用户之间的相互评论
/// - pic: 对内部的资源发表意见
enum TCommentType: Int{
    case topic
    case user
    case pic
}
extension TCommentType: Codable{}

/// 讨论的主题
struct TTopic: SQLiteModel {
    var id: Int?
    var ownerId: Int
    var topicName: String
    init(name: String, userId creater: Int) {
        self.topicName = name
        self.ownerId = creater
    }
}

struct TTopicAddTopicName: SQLiteModel , SQLiteMigration{
    var id: Int?
    
    static func prepare(on conn: SQLiteConnection) -> Future<Void>{
        let defaultValueConstraint = SQLiteColumnConstraint.default(GenericSQLExpression<SQLiteLiteral, SQLiteBind, SQLiteColumnIdentifier, SQLiteBinaryOperator, SQLiteFunction, SQLiteQuery>._literal(""))
        
        return SQLiteDatabase.update(TTopic.self, on: conn, closure: { (builder) in
            builder.field(for: \.topicName, type: SQLiteDataType.text, defaultValueConstraint)
        })
    }
    
    static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        let resut =  conn.eventLoop.newPromise(Void.self)
        
        resut.succeed()
        return resut.futureResult
        
    }
}

/// 用户发表的评论
struct TComment: SQLiteModel {
    var id: Int?
    var type: TCommentType
    /// 关于XX的评论
    var aboutId: Int
    //发表人
    var ownerId: Int
}

/// 主题 和 评论 1：n
/// 评论 和 人  父与子关系
/// 主题 和 创建人 父与子关系


/// 账户
struct TUser: SQLiteModel {
    var id: Int?
    var nickName: String
    var password: String
}

struct TResource : SQLiteModel  {
    var id: Int?
    var ownerId:Int
    var relativePath: String
    var type: TResourceType
    
    /// 资源类型
    ///
    /// - pic: 图片
    /// - mov: 视频
    enum TResourceType: Int {
        case pic = 0
        case mov = 1
    }
    
}
extension TResource.TResourceType: Codable{}


extension TTopic{
    //主题下的评论
    var comments: Children<TTopic, TComment>{
        return children(\.aboutId)
    }
    
    /// 创建人de主题
    var owner:Parent<TTopic, TUser>{
        return parent(\.ownerId)
    }
}
extension TUser{
    
    /// 个人发表的评论
    var comments:Children<TUser, TComment>{
        return children(\.ownerId)
    }
    var topics: Children<TUser, TTopic>{
        return children(\.ownerId)
    }
}
struct TUserAddNickName: SQLiteModel, SQLiteMigration {
    var id: Int?
    
        static func prepare(on conn: SQLiteConnection) -> Future<Void>{
            
            return SQLiteDatabase.update(TUser.self, on: conn, closure: { (builder) in
                let defaultValueConstraint = SQLiteColumnConstraint.default(GenericSQLExpression<SQLiteLiteral, SQLiteBind, SQLiteColumnIdentifier, SQLiteBinaryOperator, SQLiteFunction, SQLiteQuery>._literal(""))
                builder.field(for: \.nickName, type: SQLiteDataType.text, defaultValueConstraint)
            })
        }
    
    static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        let resut =  conn.eventLoop.newPromise(Void.self)
        
        resut.succeed()
        return resut.futureResult
        
    }
    
}
struct TUserAddNickPassword: SQLiteModel, SQLiteMigration {
    var id: Int?
    
    static func prepare(on conn: SQLiteConnection) -> Future<Void>{
        let defaultValueConstraint = SQLiteColumnConstraint.default(GenericSQLExpression<SQLiteLiteral, SQLiteBind, SQLiteColumnIdentifier, SQLiteBinaryOperator, SQLiteFunction, SQLiteQuery>._literal(""))

        return SQLiteDatabase.update(TUser.self, on: conn, closure: { (builder) in
            builder.field(for: \.password, type: SQLiteDataType.text, defaultValueConstraint)
        })
    }
    
    static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        let resut =  conn.eventLoop.newPromise(Void.self)
        
        resut.succeed()
        return resut.futureResult
        
    }
    
}


extension TUser: SQLiteMigration{

}
extension TComment : SQLiteMigration{}
extension TTopic: SQLiteMigration{}
extension TResource: SQLiteMigration{}
