import FluentSQLite
import Vapor
import Leaf
/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    try sql_routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .memory)
 let sqlite = try SQLiteDatabase(storage: SQLiteStorage.file(path: "hello"), threadPool: BlockingIOThreadPool.init(numberOfThreads: 100))
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.enableLogging(on: DatabaseIdentifier<SQLiteDatabase>.sqlite)
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    services.register(migrations)

    
/// Leaf
    try services.register(LeafProvider())
//    PlaintextRenderer LeafRenderer 这两种可供选择
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
