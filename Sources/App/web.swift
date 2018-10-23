//
//  web.swift
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

extension SKUser: SessionAuthenticatable{}

func web_routes(_ router: Router) throws -> Void {
    let session = SKUser.authSessionsMiddleware()
    //将系统分为web和API两步分，然后分别添加对应的认证
    let auth = router.grouped("web")
        .grouped(SessionsMiddleware.self)//< 将session添加值分组d中十分必要
        .grouped(session) //<！基于用户Model SKUser的的认证
    
    auth.get("hello") { (req) -> EventLoopFuture<View> in
        let user =  try req.requireAuthenticated(SKUser.self)
        let logger = try req.make(Logger.self)
        logger.debug("\(user)")
        return try req.view().render("base")
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
