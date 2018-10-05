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
    
    
   
    router.get("email", String.parameter) { req -> EventLoopFuture<HTTPResponseStatus> in
        
        
        let smtp: SMTP = SMTP.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
      let fromUser =  Mail.User(name: "注册码确认邮件", email: "lylapp@163.com")
        let email = try req.parameters.next(String.self)
        let toUser = Mail.User.init(email: email)
        
let mail = Mail(from: fromUser
    , to: [toUser]
    , cc: [], bcc: []
    , subject: "欢迎®️"
    , text: "您的注册码是\(VerfiyCodeRender.renderInstance.default)"
    , attachments: []
    , additionalHeaders: [:])
        
        let result = req.eventLoop.newPromise(Bool.self)
        
        smtp.send(mail, completion: { (error) in
            print(error as Any)
               result.succeed(result: error == nil)
            
        })
//        HTTPResponseStatus
     return   result.futureResult.map({ (b) -> HTTPResponseStatus in
        return b ? .ok : .expectationFailed
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
