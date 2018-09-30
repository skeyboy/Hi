import Vapor
import Leaf
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
    struct User: Content {
        var name: String
        var age: Int
        var image: Data
    }
    router.post("users") { (req) -> Future<HTTPStatus> in
       
        return try! req.content.decode(User.self).map(to: HTTPStatus.self, { (user) -> HTTPStatus in
            print(user.name) // "Vapor"
            print(user.age) // 3
            print(user.image) // Raw image data
            return .ok
        })
    }
    router.get("multipart") { (req) -> User in
        let res = req.response()
        let user = User(name: "Vapor", age: 12, image: Data())
       try! res.content.encode(user, as: MediaType.multipart)
        return user
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
    
    router.get("user") { (req) -> User in
        let user: User = try! req.query.decode(User.self)
        try! req.content.encode(user, as: MediaType.urlEncodedForm)
                return user
        
        
    }
    
    
    
    
}

