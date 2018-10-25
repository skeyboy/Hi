//
//  token.swift
//  Hello
//
//  Created by sk on 2018/10/24.
//

import Foundation
import Foundation
import Vapor
import FluentSQLite

import SQLite
import DatabaseKit
import Crypto
import Authentication

extension SKUser{
    var tokens: Children<SKUser, SKUserToken> {
        return children(\.userID)
    }
}
public struct SKUserToken: SQLiteModel {
    public var id: Int?
    var string: String
    var userID: SKUser.ID
    
    var user: Parent<SKUserToken, SKUser> {
        return parent(\.userID)
    }
}
extension SKUserToken: Token{
    public static var userIDKey: WritableKeyPath<SKUserToken, Int> {
        return \.userID
    }
    
    public typealias UserType = SKUser
    
    public typealias UserIDType = Int
    
    public static var tokenKey: WritableKeyPath<SKUserToken, String> {
        return \.string

    }
    }
extension SKUser: TokenAuthenticatable{
    public typealias TokenType = SKUserToken
}
func token_routes(_ router: Router) throws -> Void {
    let token = SKUser.tokenAuthMiddleware()
  let auth =  router.grouped("api","toekn")
        .grouped(token)
    .grouped(TokenAuthenticationMiddleware<SKUser>.self)
        
       auth.get("hello") { (req) -> String in
       
        let user = try req.requireAuthenticated(SKUser.self)

            return "Hello, \(user)"
            
        
    }
    auth.get("login",Int.parameter) { (req) -> Future<String> in
        let id = try req.parameters.next(Int.self)
        return SKUser.find(id, on: req).map({ (user:SKUser?) -> (String) in
            guard let user = user else{
                throw Abort(.badRequest)
            }
            try req.authenticate(user)
            return "Logged in\(user)"
        })
    }
}
