//
//  sql_routes.swift
//  Hello
//
//  Created by sk on 2018/9/30.
//

import Vapor
import SQLite
import DatabaseKit
func sql_routes(_ router: Router) throws -> Void {
    struct SQLiteVersion: Codable {
        let version: String
    }
    
    router.get("sql") { (req) -> EventLoopFuture<String> in
        
        let result =  req.withPooledConnection(to: DatabaseIdentifier<SQLiteDatabase>.sqlite, closure: { (conn:SQLiteConnection) -> EventLoopFuture<[SQLiteVersion]> in
            return   conn.select().column(GenericSQLExpression.function("sqlite_version"), as: GenericSQLIdentifier.init("version")).all(decoding:SQLiteVersion.self)
        })
        
        return   result.map({ (rows) -> String in
            return rows[0].version
        })
    }
}
