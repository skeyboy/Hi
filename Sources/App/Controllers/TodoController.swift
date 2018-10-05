import Vapor

/// Controls basic CRUD operations on `Todo`s.
final class TodoController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Todo]> {
        return Todo.query(on: req).filter(\.id, .greaterThan, 1).all()
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> Future<Todo> {
        
        return try req.content.decode(Todo.self).flatMap { todo in
            return todo.save(on: req)
        }
    }

    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Todo.self).flatMap { todo in
            return todo.delete(on: req)
        }.transform(to: .ok)
    }
    func find(_ req: Request)throws -> EventLoopFuture<Todo?> {
        return Todo.find(43, on: req )
    }
    func query(_ req: Request)throws -> EventLoopFuture<Todo?> {
        return Todo.query(on: req)
            .filter(\.title , .equal, "title")
            .filter(\.id, .greaterThan, 2)
            .range(..<5)
            .sort(\.title, .descending)
            .first()
    }
    
    
}
