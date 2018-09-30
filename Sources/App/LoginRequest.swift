//
//  LoginRequest.swift
//  Hello
//
//  Created by sk on 2018/9/29.
//

import Vapor
struct LoginRequest: Content {
    var email: String
    var password : String
    public static var defaultContentType: MediaType {
//        return .urlEncodedForm
        return .json //默认的
    }
}
