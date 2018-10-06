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
    
    router.get("regist", use: SKUserController().regist)
    
    router.post("users") { (req) -> Future<User> in
        print( req.http.headers.firstValue(name: HTTPHeaderName.contentDisposition))
        print(req.http.contentType)
        return try! req.content.decode(User.self ).map(to: User.self, { (user) -> User in
            print(user.name) // "Vapor"
            print(user.age) // 3
            print(user.image) // Raw image data
           
            let path =  try req.sharedContainer.make(DirectoryConfig.self).workDir + "Public/"
            do{
                try user.image.write(to: URL(fileURLWithPath: path+user.name + "\(Date().timeIntervalSince1970)" +  user.imageType.type))
                    
               
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
    
    /*
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
    */
    router.get("email", use: SKUserController().sendCode)

    
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
//    var path: String
    var image: Data
    var imageType: Int
    static var defaultContentType: MediaType  = .formData
}
extension Int{
    var type: String{
        switch self {
        case 0:
            return ".ipa"
        case 1:
            return ".apk"
        case 2:
            return ".dmg"
        case 3:
            return ".png"
        case 4:
            return ".mov"
        default:
            return ".txt"
        }
    }
}
