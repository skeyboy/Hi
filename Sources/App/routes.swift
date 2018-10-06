import Vapor
import Leaf
import Authentication
import SwiftSMTP
import SQLite
import DatabaseKit

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    
    
    // Basic "Hello, world!" example
    
    router.get("hello") { req in
        return "Hello, world!"
    }
    router.get("/") { (req) -> Future<View> in
        return try! req.view().render("index")
    }
    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    let hi = HelloController()
    
    router.get("hi", use: hi.greet)
    router.get("users",Int.parameter,"name",String.parameter) { (req) -> String in
        let result = req.parameters.values.map({ (p) -> String in
            return "#\(p.slug) \(p.value)"
        })
        let id = try req.parameters.next(Int.self)
        let name = try req.parameters.next(String.self)
        return "requested id #\(id) \(result)"
    }
    
    router.get("leaf") { (req) -> Future<View> in
        
        struct Header: Codable {
            var name: String
            var value: String
        }
        struct Headers: Codable {
            var headers = [Header]()
        }
        var headers: Headers =     Headers()
        let headList =  req.http.headers.map({ (name, value) -> Header in
            return Header(name: name, value: value)
        })
        
        headers.headers.append(contentsOf: headList)
        
        return  try req.view().render("leaf", headers)
        //        return try   req.view().render("leaf", userInfo: ["headers": SolarSystem() ])
    }
    
    router.get("embed") { (req) -> Future<View> in
        return try! req.view().render("child", userInfo: ["title":"Hello","list":["23","2332"]])
        return try! req.view().render("child", ["title":"Hello "] )
    }
    
    
    router.post("users") { (req) -> Future<User> in
        print(req.response().http.headers)
        return try! req.content.decode(User.self, maxSize: 1024 * 1024 * 100 ).map(to: User.self, { (user) -> User in
            print(user.name) // "Vapor"
            print(user.age) // 3
            print(user.image) // Raw image data
            let path =  try req.sharedContainer.make(DirectoryConfig.self).workDir + "Public/"
            do{
                try user.image.write(to: URL(fileURLWithPath: path+user.name+".png"))
            } catch{
                
            }
            return user
            //            return .ok
        })
    }
    
    
    router.grouped("sessions").grouped(SessionsMiddleware.self).get("foo") { (req) -> String in
        try! req.session()["name"] = UUID.init(uuidString: "d")?.uuidString
        
        return try! req.session()["name"] ?? ""
    }
    
    //    Decode
    router.post("login") { (req) -> Future<HTTPStatus> in
        return try! req.content.decode(LoginRequest.self).map({ (login) -> HTTPStatus in
            
            return HTTPStatus.ok
        })
    }
    
    router.post(LoginRequest.self, at: "login") { (req, login) -> LoginRequest in
        
        print("\(login.email) \(login.password)")
        return login
        //        return HTTPStatus.ok
    }
    
    router.post("app") { (req) -> Future<HTTPStatus> in
        return try req.content.decode(History.self).map(to: HTTPStatus.self, { (history) -> HTTPStatus in
            
            
            return .ok
        })
    }
    router.get("user") { (req) -> User in
        let user: User = try! req.query.decode(User.self)
        try! req.content.encode(user, as: MediaType.urlEncodedForm)
        return user
        
        
    }
    
    router.get("regist") { (req) ->  EventLoopFuture<String> in
        struct InnerUser: Content{
            var name: String
            var email: String
            var password:String
            static var defaultContentType: MediaType{
                return .urlEncodedForm
            }
        }
        
        let user =  try!  req.query.decode(InnerUser.self)
        
        let skUser: SKUser = SKUser.init(name: user.name, email: user.email, password: user.password)
        
        return  SKUser.query(on: req)
            .filter(\SKUser.email,
                    .equal,
                    try! MD5.hash(skUser.email).base64EncodedString() )
            .first()
            .flatMap({ (u) -> EventLoopFuture<String> in
                if u != nil {
                    return   u!.save(on: req).map({ (x) -> String in
                        return "\(x)"
                    })
                }else {
                    let r =   req.eventLoop.newPromise(String.self)
                    r.succeed(result: "邮箱已存在")
                    return r.futureResult
                }
            })
    }
    
    router.get("email") { req -> EventLoopFuture<String> in
        struct Email: Content {
            var email: String
        }
        let email: Email = try req.query.decode(Email.self)
        
        return    SKRegistVerfiy.query(on: req).filter(\.email, .equal, email.email).first().flatMap({ (verfiy) -> EventLoopFuture<String> in
            
            
            if let v = verfiy {//已经存在
                let result = req.eventLoop.newPromise(String.self)
                
                result.succeed(result: v.emailExistMessage)
                return result.futureResult
                
            }else{
                
                let reg =  SKRegistVerfiy.init(email: email.email)
                return  reg.save(on: req).flatMap({ (skVer) -> EventLoopFuture<String> in
                    
                    let smtp: SMTP = SMTP.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
                    let fromUser =  Mail.User(name: "注册码确认邮件", email: "lylapp@163.com")
                    let email = skVer.email
                    let toUser = Mail.User.init(email: email)
                    
                    let mail = Mail(from: fromUser
                        , to: [toUser]
                        , cc: [], bcc: []
                        , subject: "欢迎®️"
                        , text: skVer.message
                        , attachments: []
                        , additionalHeaders: [:])
                    let result = req.eventLoop.newPromise(String.self)
                    
                    smtp.send(mail, completion: { (error) in
                        print(error as Any)
                        if let error = error {
                            result.fail(error: error)
                        }else{
                            result.succeed(result: skVer.message)
                        }
                    })
                    return result.futureResult
                })
            }
        })
    }
    
    router.get("app") { (req) -> Future<HTTPStatus> in
        return try req.content.decode(User.self).map(to: HTTPStatus.self) { user in
            print(user.name) // "Vapor"
            print(user.age) // 3
            print(user.image) // Raw image data
            return .ok
        }
    }
    
}



struct User: Content {
    var name: String
    var age: Int
    var path: String
    var image: Data
    static var defaultContentType: MediaType  = .formData
}
