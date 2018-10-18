//
//  theme.swift
//  Hello
//
//  Created by sk on 2018/10/17.
//

import Foundation
import Vapor
import SQLite
import DatabaseKit

struct TResponse<T> where T: Content{
    var code: Int
    var msg: String
    var data: T
}
extension TResponse: Content{}
struct TRespData<D>  where D: Content{
    var value: D
    var code: Int
}
extension TRespData: Content{}


func theme_routes(_ router: Router) throws -> Void {
let v1 = router.grouped("api","v1")
    
    v1.get("regist","nickname",String.parameter, "password", String.parameter) { (req) -> EventLoopFuture<TResponse<TRespData<String>> > in
        
        let nickName: String = try! req.parameters.next(String.self)
        let password: String = try! req.parameters.next(String.self)
      return  req.transaction(on: .sqlite, { (conn) -> EventLoopFuture<TResponse<TRespData<String>>> in
        
        return TUser.query(on: req).filter(\.nickName, .equal, nickName).first().flatMap({ (u) -> EventLoopFuture<TRespData<String>> in
                
                if u != nil {
                    let result = req.eventLoop.newPromise(TRespData<String>.self)
                    
                    result.succeed(result: TRespData.init(value: "用户已存在", code: 0))
                    return result.futureResult
                    
                }else{
                    
                    return  TUser.init(id: nil, nickName: nickName, password: password).create(on: req)
                        .flatMap({ (u) -> EventLoopFuture<TRespData<String>> in
                            let result = req.eventLoop.newPromise(TRespData<String>.self)
                            result.succeed(result: TRespData.init(value: "注册成功", code: 1))
                            return result.futureResult
                            
                        })
                }
                
        }).flatMap({ (d) -> EventLoopFuture<TResponse<TRespData<String>>> in
          let value =  TResponse<TRespData<String>>.init(code: d.code, msg: "", data: d)
            let result = req.eventLoop.newPromise(TResponse<TRespData<String>>.self)
//            let smtp: SKSmtp = try! req.make(SKSmtp.self)
            
            
            result.succeed(result: value)
            return result.futureResult
            
        })
        
        })
       
        
//        return "\(try! req.parameters.next(String.self))" + "\(try! req.parameters.next(String.self))"
    }
    struct TU: Content {
        var topic: TTopic
        var owner: TUser
        var comments: [TComment]?
    }
    struct TResult: Content{
        var topics: [TU] = [TU]()
        init() {
            
        }
    }
    v1.get("a") { (req) -> EventLoopFuture<View> in
        
     return   TTopic.query(on: req).all().flatMap({ (ts) -> EventLoopFuture<[(TTopic, TUser)]> in
            
            let value: [EventLoopFuture<(TTopic, TUser)>] = ts.map({ (t: TTopic) -> EventLoopFuture<(TTopic, TUser)> in
                
              return  t.owner.query(on: req).first().flatMap({ (u) -> EventLoopFuture<(TTopic, TUser)> in
                    let result = req.eventLoop.newPromise((TTopic, TUser).self)
                result.succeed(result: (t, u!))
                    return result.futureResult
                })
            })
            
           return value.flatten(on: req)
        }).flatMap({ (tus:[(TTopic, TUser)]) -> EventLoopFuture<[(TTopic, TUser, [TComment]?)]> in
         
            let values = tus.map({ (tu:(TTopic, TUser)) -> EventLoopFuture<(TTopic, TUser, [TComment]?)> in
                
             return  try!  tu.0.comments.query(on: req).all().flatMap({ (comments:[TComment]) -> EventLoopFuture<(TTopic, TUser, [TComment]?)> in
                    
                    let result = req.eventLoop.newPromise((TTopic, TUser, [TComment]?).self)
                    result.succeed(result: (tu.0, tu.1, comments))
                    return result.futureResult
                })
                
            })
            
            return values.flatten(on: req)
            
        }).flatMap({ (items:[(TTopic, TUser, [TComment]?)]) -> EventLoopFuture<View> in
            
            var tResult = TResult()

            items.forEach({ (value:(TTopic, TUser, [TComment]?)) in
             let tu =  TU(topic: value.0, owner: value.1, comments: value.2)
                tResult.topics.append(tu)
            })
            
            return  try req.view().render("themes", tResult)
            
        })
        
//        return ""
        
    }
    struct Theme: Content {
        var topic: String
        var userId: Int
    }
    
    struct TsComment{
        var userName: String
    }
    
    struct Ts: Content{
        var topics:[TTopic]
    }
    struct Tc: Content {
        var topocs: TTopic
        var comments: [TComment]
    }
    v1.get("theme/create") { (req) -> EventLoopFuture<View>  in
        
        let theme = try! req.query.decode(Theme.self)

        return TTopic.init(name: theme.topic, userId: theme.userId).create(on: req).then({ (t) -> EventLoopFuture<Ts> in
            
            return  TTopic.query(on: req).all().flatMap({ (topics) -> EventLoopFuture<Ts> in
                
                let result = req.eventLoop.newPromise(Ts.self)
                result.succeed(result: Ts.init(topics: topics))
                return result.futureResult
            })
            
        }).flatMap({ (ts) -> EventLoopFuture<View> in
            
            
//        let value =    ts.topics.map({ (t:TTopic) -> EventLoopFuture<View> in
//                
//                return try! t.comments.query(on: req).all().flatMap({ (tc) -> EventLoopFuture<Tc> in
//                    let result = req.eventLoop.newPromise(Tc.self)
//                    result.succeed(result: Tc(topocs: t, comments: tc))
//                    return result.futureResult
//                })
//            })
            
//            let result = req.eventLoop.newPromise([EventLoopFuture<Tc> ].self)
//            result.succeed(result: value)
            
//            return result.futureResult
            return try! req.view().render("theme", ts)
        })
//        req.view().render("theme", <#T##context: Encodable##Encodable#>)
//        return ""
       
//        return "\(theme)"
    }
}


