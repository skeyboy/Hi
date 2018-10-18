// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Hello",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        
        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/multipart.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        /// mail Server
        .package(url: "https://github.com/IBM-Swift/Swift-SMTP.git", from: "4.0.1"),
//        .package(url: "https://github.com/qutheory/vapor-mustache.git", from: "0.11.0"),
//        git@github.com:skeyboy/SKSmtp.git
       .package(url: "https://github.com/skeyboy/SKSmtp.git", from:"0.0.3"),

        ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite","Authentication","SwiftSMTP", "Vapor","Leaf","Multipart"/*,"VaporMustache"*/,"SKSmtp"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

