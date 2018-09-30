//
//  HelloController.swift
//  Run
//
//  Created by sk on 2018/9/29.
//

import Foundation
import Vapor
final class HelloController {
    func greet(_ req: Request) throws -> String {
        return "Hello!"
    }
}
