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
import Crypto
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


struct TU: Content {
    var topic: TTopic
    var owner: TUser
    var resources:[TTResource]
    var comments: [TUC]?
}

struct TUC: Content {
    var comment: TComment?
    var subComments: [TUC]?
}
struct TResult: Content{
    var topics: [TU] = [TU]()
    init() {
        
    }
}


func theme_routes(_ router: Router) throws -> Void {
   let password = TUser.basicAuthMiddleware(using: BCryptDigest())
//    router.grouped([password]).grouped("api","v1")
    let v1 = router.grouped([password]).grouped("api","v1")
    v1.get("test") { (req) -> String in
        let user =  try req.requireAuthenticated(TUser.self)
        return "Hello \(user.nickName)"
    }
    //用户注册
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
        
       
    }
   
    //查看所有主题和评论
    v1.get("a") { (req) -> EventLoopFuture<View> in
        
        return   TTopic.query(on: req).all().flatMap({ (ts) -> EventLoopFuture<[(TTopic, TUser?)]> in
            
            let value: [EventLoopFuture<(TTopic, TUser?)>] = ts.map({ (t: TTopic) -> EventLoopFuture<(TTopic, TUser?)> in
                
                return  t.owner.query(on: req).first().flatMap({ (u) -> EventLoopFuture<(TTopic, TUser?)> in
                    let result = req.eventLoop.newPromise((TTopic, TUser?).self)
                    result.succeed(result: (t, u))
                    return result.futureResult
                })
            })
            
            return value.flatten(on: req)
        }).flatMap({ (tus:[(TTopic, TUser?)]) -> EventLoopFuture<[(TTopic, TUser?,[TTResource], [TUC]?)]> in
            
            let values = tus.map({ (tu:(TTopic, TUser?)) -> EventLoopFuture<(TTopic, TUser?,[TTResource], [TUC]?)> in
                
                return  try!  tu.0.comments.query(on: req).all().flatMap({ (comments:[TComment]) -> EventLoopFuture<(TTopic, TUser?,[TTResource], [TUC]?)> in
                    
                    
                    let tucs:[EventLoopFuture<TUC>]  =  comments.map({ (tc:TComment) -> EventLoopFuture<TUC> in
                        
                        return    TComment.query(on: req)
                            
                            .group(SQLiteBinaryOperator.or, closure: { (or) in
//                            or.group(SQLiteBinaryOperator.and, closure: { (and) in
//                                //评论的子评论
//                                and.filter(\.aboutId, .equal, tc.id!)
//                                and.filter(\.attatchId, .equal, tu.0.id!)
//                                and.filter(\.attatchId, .notEqual, 0)
//                                and.filter(\.type, .equal, TCommentType.user.rawValue)
//
//                            })
                            or.group(SQLiteBinaryOperator.and, closure: { (and) in
                                //针对主题的直接评论
                                and.filter(\.aboutId, .equal, tu.0.id!)
//                                and.filter(\.attatchId, .equal, 0)
                                and.filter(\.type, .equal, TCommentType.topic.rawValue)
                            })
                        
                        })
                            .all()
                            .flatMap({ (tcs:[TComment]) ->
                                EventLoopFuture<TUC> in
                                
                                let tuc: TUC = TUC.init(comment: tc, subComments: tcs.map({ (tc) -> TUC in
                                    return TUC.init(comment: tc, subComments: nil)
                                }))
                                let result = req.eventLoop.newPromise(TUC.self)
                                
                                result.succeed(result: tuc)
                                return result.futureResult
                            })
                        
                    })
                    
                    return  tucs.flatten(on: req).flatMap({ (tucList:[TUC]) -> EventLoopFuture<(TTopic, TUser?,[TTResource], [TUC]?)> in
                        
                    return  try  tu.0.resources.query(on: req).all().flatMap({ (resources:[TTResource]) -> EventLoopFuture<(TTopic, TUser?, [TTResource], [TUC]?)> in
                            
                            let result = req.eventLoop.newPromise((TTopic, TUser?, [TTResource], [TUC]?).self)
                            
                            result.succeed(result: (tu.0, tu.1, resources, tucList))
                            return result.futureResult
                        })
                        
//                        let result = req.eventLoop.newPromise((TTopic, TUser?, [TUC]?).self)
//
//                        result.succeed(result: (tu.0, tu.1, tucList))
//                        return result.futureResult
                    })
                })
                
            })
  
            return values.flatten(on: req)
            
        }).flatMap({ (items:[(TTopic, TUser?,[TTResource], [TUC]?)]) -> EventLoopFuture<View> in
            
            var tResult = TResult()
            
            items.forEach({ (value:(TTopic, TUser?,[TTResource], [TUC]?)) in
                let tu =  TU(topic: value.0, owner: value.1!, resources:value.2, comments: value.3)
                tResult.topics.append(tu)
            })
            
            return  try req.view().render("themes", tResult)
        })
    }
    struct Theme: Content {
        var topic: String
        var userId: Int
        var file1: Data?
        var file2: Data?
    }
    
    struct TsComment{
        var userName: String
    }
    
    struct Ts: Content{
        var topics:[TTopic]
        var resources:[TTResource]
        
        
    }
    struct Tc: Content {
        var topocs: TTopic
        var comments: [TComment]
    }
    //创建主题
    v1.post("theme/create") { (req) -> EventLoopFuture<View>  in
        
      return try  req.content.decode(Theme.self).flatMap({ (theme) -> EventLoopFuture<View> in
        
        return TTopic.init(name: theme.topic, userId: theme.userId).create(on: req).then({ (t) -> EventLoopFuture<View> in
            
            let filePaths =   [theme.file1, theme.file2].map({ (d) -> EventLoopFuture<TTResource> in
                let relativePath = "\(Date().timeIntervalSince1970*1000+1).png"
                let file =  "/Users/sk/Documents/vapor/Hello/Public/"+relativePath

                if let data = d{
                    try!   data.write(to: URL.init(fileURLWithPath: file))
                    
                 return try!  TTResource.init(pic: relativePath, creater: theme.userId, topic: t.id!).create(on: req)
                }else{
                let result = req.eventLoop.newPromise(TTResource.self)
                    result.succeed(result: TTResource.init(pic: file, creater: theme.userId, topic: t.id!))
                    return result.futureResult
                }
            })
            
         return   filePaths.flatten(on: req).then({ (resources:[TTResource]) -> EventLoopFuture<Ts> in
                return  TTopic.query(on: req).all().flatMap({ (topics) -> EventLoopFuture<Ts> in
                    
                    let result = req.eventLoop.newPromise(Ts.self)
                    result.succeed(result: Ts.init(topics: topics, resources: resources))
                    return result.futureResult
                })
                
            }).flatMap({ (ts) -> EventLoopFuture<View> in
                
                
                
                return try! req.view().render("theme", ts)
            })
            })
            
        })
        
//        let theme = try! req.query.decode(Theme.self)
        
        
        
    }
    
    
    struct TopicComment : Content {
        var fromId: Int
        var toId: Int
        var attatchId: Int
        var content: String
        var type: TCommentType
        
        var file1:Data?
        var file2: Data?
        static var defaultContentType: MediaType  = .formData
    }
    v1.post("theme/comment") { (req) -> EventLoopFuture<TComment> in
        
       
        
        return try req.content.decode(TopicComment.self).flatMap({ (topicComment:TopicComment) -> EventLoopFuture<TComment> in
//         var filePaths =   [topicComment.file1, topicComment.file2].map({ (d) -> String? in
//                if let data = d{
//                  let file =  "/Users/sk/Documents/vapor/Hello/Public/\(Date().timeIntervalSince1970*1000+1).png"
//                 try!   data.write(to: URL.init(fileURLWithPath: file))
//                    return file
//                }else{
//                    return nil
//                }
//            })
            var comment: TComment
            
            return  TComment.init(aboutId: topicComment.toId, ownerId: topicComment.fromId, type: topicComment.type, content: topicComment.content, attachId: topicComment.attatchId)
                .create(on: req).flatMap({ (comment) -> EventLoopFuture<TComment> in
                
                let result = req.eventLoop.newPromise(TComment.self)
                result.succeed(result: comment)
                return result.futureResult
            })
        })

    }
    struct Images: Content{
        var file1:Data?
        var file2: Data?
        static var defaultContentType: MediaType  = .formData
    }
    
    //html post form 测试
    v1.post("double") { (req) -> EventLoopFuture<String> in
       
        return try! req.content.decode(Images.self).flatMap({ (imgs) -> EventLoopFuture<String> in
            if let file1 = imgs.file1 {
                
                try!   file1.write(to: URL.init(fileURLWithPath: "/Users/sk/Documents/vapor/Hello/Public/\(Date().timeIntervalSince1970*1000+1).png"))
            }
            if let file2 = imgs.file2 {
                
                try!   file2.write(to: URL.init(fileURLWithPath: "/Users/sk/Documents/vapor/Hello/Public/\(Date().timeIntervalSince1970*1000+2).png"))
            }
            
            let result = req.eventLoop.newPromise(String.self)
            
            result.succeed(result: "OK")
            return result.futureResult
        })
        
//        return ""
    }
}


func subComments( by tuc:  TUC, with req: Request){
    if let comment = tuc.comment {
        TComment.query(on: req).filter(\.aboutId, SQLiteBinaryOperator.equal, comment.id!).first().flatMap { (c:TComment?) -> EventLoopFuture<TUC> in
            let result = req.eventLoop.newPromise(TUC.self)
            var t: TUC = TUC.init(comment: comment, subComments: nil)
            TUC.init(comment: comment, subComments: [t] )
            result.succeed(result: t)
            return result.futureResult
        }
    }
}
