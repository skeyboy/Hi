import FluentSQLite
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    let smtpConfig =  SKSmtpConfig.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
    
    services.register(smtpConfig)
    try services.register(SKSmtpProvider())
    
    
    //configure.swift  func configure
    var nioServerConfig = NIOServerConfig.default()
    //修改为 100 MB
    nioServerConfig.maxBodySize = 100 * 1024 * 1024
    services.register(nioServerConfig)
    
    // register Authentication provider
    try services.register(AuthenticationProvider())
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    try sql_routes(router)
    services.register(router, as: Router.self)
    
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    try services.register(SessionsMiddleware.self)
    
    
    
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
    
    migrations.add(model: Galaxy.self, database: .sqlite)
    
    migrations.add(model: Planet.self, database: .sqlite)
    
    migrations.add(model: PlanetTag.self, database: .sqlite)
    migrations.add(model: Tag.self, database: .sqlite)
    migrations.add(model: SKUser.self, database: .sqlite)
    migrations.add(model: SKRegistVerfiy.self, database: .sqlite)
    migrations.add(model: SKInstallPackage.self, database: .sqlite)
    migrations.add(model: SKPackage.self, database: .sqlite)
    migrations.add(model: SKPackageScribePivot.self, database: .sqlite)
    
    
     
    migrations.add(model:TComment.self, database: .sqlite);         migrations.add(model:TResource.self, database: .sqlite)
    migrations.add(model:TUser.self, database: .sqlite)
migrations.add(model: TTopic.self, database: .sqlite)
    //以上为数据表创建
    
    
    //数据库迁移 sqlite 一个类支持一个字段迁移【有点坑爹啊】
    migrations.add(migration: TUserAddNickName.self, database: .sqlite)
    migrations.add(migration: TUserAddNickPassword.self, database: .sqlite)
migrations.add(migration: TTopicAddTopicName.self, database: .sqlite)
    migrations.add(migration: TCommentAddContent.self, database: .sqlite)
    services.register(migrations)
    
    
    
    
    
    
    
    
    /// Leaf
    try services.register(LeafProvider())
    //    PlaintextRenderer LeafRenderer 这两种可供选择
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
