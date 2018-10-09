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
            var list:[String] = [String]()
        }
        var headers: Headers =     Headers()
        
        let headList =  req.http.headers.map({ (name, value) -> Header in
            let v = Header(name: name, value: value)
            return v
        })
        
        
        headers.headers.append(contentsOf: headList)
        headers.list = ["A", "B","C"]
        
        return  try req.view().render("leaf", headers)
        //        return try   req.view().render("leaf", userInfo: ["headers": SolarSystem() ])
    }
    
    router.get("embed") { (req) -> Future<View> in
        return try! req.view().render("child", userInfo: ["title":"Hello","list":["23","2332"]])
        return try! req.view().render("child", ["title":"Hello "] )
    }
    
    router.get("regist", use: SKUserController().regist)
    router.get("login", use: SKUserController().login)
    router.get("package", use: SKUserController().package)
    router.post("upload", use: SKUploadController().upload)
    
    
    router.post("users") { (req) -> Future<User> in
     
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
    
    router.get("ssubcribe", use: SKUserController().subcribeUserPackage)
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
    
    router.get("email", use: SKUserController().sendCode)

    
    router.get("app") { (req) -> Future<HTTPStatus> in
        return try req.content.decode(User.self).map(to: HTTPStatus.self) { user in
            print(user.name) // "Vapor"
            print(user.age) // 3
            print(user.image) // Raw image data
            return .ok
        }
    }
    
    router.get("package") { (req) -> Future<View> in
        
        SKPackage.query(on: req).all().flatMap({ (pgs) -> EventLoopFuture<View> in
            struct PInfos: Codable {
                var packages: [SKPackage] = [SKPackage]()
            }
            
            var pInfos = PInfos()
          pInfos.packages.append(contentsOf:   pgs.map({ (pk) -> SKPackage  in
                return pk
            }))
//            return try req.view().render("package.leaf", userInfo: ["list":pInfos])
            return try req.view().render("package.leaf", pInfos)
        })
//         return try req.view().render("package.leaf", userInfo: ["name":"s", "list":[1, 2,3].makeIterator()])
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
extension Int {
  public  var type: String{
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
