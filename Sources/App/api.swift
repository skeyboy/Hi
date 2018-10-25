//
//  api.swift
//  Hello
//
//  Created by sk on 2018/10/23.
//

import Foundation
import Vapor
import SQLite
import DatabaseKit
import Crypto
import Authentication


//基于密码
extension SKUser: PasswordAuthenticatable{
    
    public static var usernameKey: WritableKeyPath<SKUser, String> {
        return \.name
    }
    
    public static var passwordKey: WritableKeyPath<SKUser, String> {
       return \.password
    }
    
    
}

func api_routes(_ router: Router) throws -> Void {
    let password = SKUser.basicAuthMiddleware(using: BCryptDigest())
    let v1 = router.grouped("api","v1")
    
    let vertify = v1.grouped(password)
    
    vertify.get("hello") { (req) -> String in
        
        let user =  try req.requireAuthenticated(SKUser.self)
        
        return "Hello, \(user)"
    }
    vertify.get("login",Int.parameter) { (req) -> Future<String> in
        let id = try req.parameters.next(Int.self)
        return SKUser.find(id, on: req).map({ (user:SKUser?) -> (String) in
            guard let user = user else{
                throw Abort(.badRequest)
            }
            try req.authenticate(user)
            return "Logged in\(user)"
        })
    }}
