//
//  SKSmtpProvider.swift
//  Hello
//
//  Created by sk on 2018/10/13.
//

import Foundation
import Vapor
import SwiftSMTP

public typealias Progress = ((Mail, Error?) -> Void)?

class SKSmtp : Service {
   fileprivate var smtp: SMTP?
    init(config: SKSmtpConfig) {
        self.smtp = SMTP.init(hostname: config.hostname, email: config.email, password: config.password, port: config.port, useTLS: config.useTLS, tlsConfiguration: config.tlsConfiguration, authMethods:config.authMethods, domainName: config.domainName, timeout: config.timeout)
    }
    
    /// Send an email.
    ///
    /// - Parameters:
    ///     - mail: `Mail` object to send.
    ///     - completion: Callback when sending finishes. `Error` is nil on success. (optional)
    public func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        smtp?.send(mail, completion: completion)
    }
    public func send(_ mails: [Mail],
                     progress: Progress = nil,
                     completion: Completion = nil) {
        smtp?.send(mails, progress: progress, completion: completion)
    }
}

/// 基于IBM开源的SwiftSMTP实现的 vapor server
///
///
///   let smtpConfig =  SKSmtpConfig.init(hostname: "smtp.163.com", email: "lylapp@163.com", password: "301324lee")
///    services.register(smtpConfig)
///    try services.register(SKSmtpProvider())




class SKSmtpProvider: Provider {
    func register(_ services: inout Services) throws {
        services.register { (container) -> SKSmtp in
            let config = try container.make(SKSmtpConfig.self)
           assert(config != nil, "选注册SKSmtpConfig实例，才能使用SKSmtp")
            return SKSmtp.init(config: config)
        }
    }
    func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        let result = container.eventLoop.newPromise(Void.self)
        result.succeed()
        return result.futureResult
    }
}
