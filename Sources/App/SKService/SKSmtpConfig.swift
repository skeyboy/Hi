//
//  SKSmtpConfig.swift
//  Hello
//
//  Created by sk on 2018/10/13.
//

import Foundation
import Vapor
import SwiftSMTP

public struct SKSmtpConfig : Service{
    var hostname: String
    var email: String
    var password: String
    var port: Int32 = 465
    var useTLS: Bool = false
    var tlsConfiguration: SwiftSMTP.TLSConfiguration?
    var authMethods:[ AuthMethod] = []
    var domainName: String  = "localhost"
    var timeout: UInt = 10
    init(hostname: String, email: String, password: String, port: Int32 = 465, useTLS:Bool = false,tlsConfiguration:SwiftSMTP.TLSConfiguration? = nil, authMethods:[ AuthMethod] = [], domainName: String  = "localhost", timeout: UInt = 10) {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.port = port
        self.useTLS = useTLS
        self.tlsConfiguration = tlsConfiguration
        self.domainName = domainName
        self.timeout = timeout
    }
    
    
}
