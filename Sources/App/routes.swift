import Vapor
import Leaf
import Authentication
import SwiftSMTP
import SQLite
import DatabaseKit
import CNIOOpenSSL
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
//    router.get("package", use: SKUserController().package)
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
   
    router.get("package",Int.parameter,"userId",Int.parameter) { (req) -> Future<View> in
        
        struct  PInfoList: Codable {
            var title: String = "Hello"
            var list: [PInfo] = [PInfo]()
            init(list: [PInfo] = []) {
                self.list.append(contentsOf: list)
                self.title = "Hello"
            }
        }
        struct PInfo: Codable{
            var package: SKPackage
            var user: SKUser?
            var installs: [SKInstallPackage] = [SKInstallPackage]()
            init(_ p: SKPackage) {
                package = p
            }
            init(_ p: SKPackage, user: SKUser?) {
                self.package = p
                self.user = user
            }
            init(_ p: SKPackage, user: SKUser?, installs:[SKInstallPackage]) {
                self.package = p
                self.user = user
                self.installs.append(contentsOf: installs)
            }
        }
        
        struct PInfos: Codable {
            var packages: [PInfo] = [PInfo]()
        }
        struct P: Content {
            
        
            var userId: Int
            var packageId: Int
        }
      let packageId = try req.parameters.next(Int.self)
     let userId  = try req.parameters.next(Int.self)
//       let userId = try! req.parameters.values.last?.value
//        let packageId = try! req.parameters.values.first?.value
let p = P(userId: userId, packageId: packageId)
        

        let view =  SKPackage.query(on: req).all().flatMap({ (ps) -> EventLoopFuture<PInfoList> in

            return  ps.map({ (p) -> EventLoopFuture<(SKPackage, SKUser?,[SKInstallPackage?])> in
                return p.owner.query(on: req).first().flatMap({ (u) -> EventLoopFuture<(SKPackage, SKUser?)> in
                    let resutl = req.eventLoop.newPromise((SKPackage, SKUser?).self)
                    resutl.succeed(result: (p,u))
                    return resutl.futureResult
                }).flatMap({ (pk) -> EventLoopFuture<(SKPackage, SKUser?, [SKInstallPackage?])> in
                    return try pk.0.packages.query(on: req).all().flatMap({ (pks) -> EventLoopFuture<(SKPackage, SKUser?, [SKInstallPackage?])> in
                        let resutl = req.eventLoop.newPromise((SKPackage, SKUser?,[SKInstallPackage?]).self)
                        resutl.succeed(result: (pk.0,pk.1, pks))
                        return resutl.futureResult
                    })
                })
            }).map({ (e) -> EventLoopFuture<PInfo> in

                return e.map({ (value:(SKPackage, SKUser?, [SKInstallPackage?])) -> PInfo in

                    let pInfo = PInfo(value.0, user: value.1, installs: value.2 as! [SKInstallPackage])


                    return pInfo
                })
            }).flatten(on: req).flatMap({ (ps) -> EventLoopFuture<PInfoList> in
                var pList = PInfoList(list: ps)
                pList.title = "安装包查看"
                let result  = req.eventLoop.newPromise(PInfoList.self)

                result.succeed(result: pList)
                return result.futureResult
            })
        }).flatMap({ (pList) -> EventLoopFuture<View> in
            return try req.view().render("package.leaf", pList)
        })
        return view
        


        return    SKPackageScribePivot.query(on: req).group(SQLiteBinaryOperator.or, closure: { (or) in
            or.filter(\SKPackageScribePivot.userId, .equal, p.userId).filter(\SKPackageScribePivot.packageId, .equal, p.packageId)
            or.filter(\SKPackageScribePivot.userId, .equal, p.userId)
        }).first().flatMap({ (pivot) -> EventLoopFuture<SKPackageScribePivot?> in
            let result = req.eventLoop.newPromise(SKPackageScribePivot?.self)
            result.succeed(result: pivot)
            return result.futureResult
        }).flatMap({ (pivot) -> EventLoopFuture<View> in
            if pivot != nil {
                let view =  SKPackage.query(on: req).filter(\.id, .equal, pivot!.packageId).all().flatMap({ (ps) -> EventLoopFuture<PInfoList> in

                    return  ps.map({ (p) -> EventLoopFuture<(SKPackage, SKUser?,[SKInstallPackage?])> in
                        return p.owner.query(on: req).first().flatMap({ (u) -> EventLoopFuture<(SKPackage, SKUser?)> in
                            let resutl = req.eventLoop.newPromise((SKPackage, SKUser?).self)
                            resutl.succeed(result: (p,u))
                            return resutl.futureResult
                        }).flatMap({ (pk) -> EventLoopFuture<(SKPackage, SKUser?, [SKInstallPackage?])> in
                            return try pk.0.packages.query(on: req).all().flatMap({ (pks) -> EventLoopFuture<(SKPackage, SKUser?, [SKInstallPackage?])> in
                                let resutl = req.eventLoop.newPromise((SKPackage, SKUser?,[SKInstallPackage?]).self)
                                resutl.succeed(result: (pk.0,pk.1, pks))
                                return resutl.futureResult
                            })
                        })
                    }).map({ (e) -> EventLoopFuture<PInfo> in

                        return e.map({ (value:(SKPackage, SKUser?, [SKInstallPackage?])) -> PInfo in

                            let pInfo = PInfo(value.0, user: value.1, installs: value.2 as! [SKInstallPackage])


                            return pInfo
                        })
                    }).flatten(on: req).flatMap({ (ps) -> EventLoopFuture<PInfoList> in
                        var pList = PInfoList(list: ps)
                        pList.title = "安装包查看"
                        let result  = req.eventLoop.newPromise(PInfoList.self)

                        result.succeed(result: pList)
                        return result.futureResult
                    })
                }).flatMap({ (pList) -> EventLoopFuture<View> in
                    return try req.view().render("package.leaf", pList)
                })
                return view
            }else{
                return try req.view().render("index")
            }
        })


        
        
            
//            .flatMap({ (pInfo) -> EventLoopFuture<View> in
//      return  pInfo.flatMap({ (ps) -> EventLoopFuture<View> in
//        var pInfoList = PInfoList()
//
//        pInfoList.list.append(contentsOf: ps)
//        return try req.view().render("package.leaf", pInfoList, userInfo: [:])
//
//        })
//      })
        return SKPackage.query(on: req).all().flatMap({ (pgs) -> EventLoopFuture<View> in
            
           
            
            
            var pInfos = PInfos()
            pInfos.packages.append(contentsOf:   pgs.map({ (pk) -> PInfo  in
                let pInfo: PInfo = PInfo(pk)
                return pInfo
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
extension String{
    var `int`: Int {
        return Int(self)!
    }
}
