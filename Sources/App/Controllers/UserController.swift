//
//  UserController.swift
//  Hello
//
//  Created by sk on 2018/10/5.
//

import Foundation
import Vapor
import SQLite
import DatabaseKit
final class SKUserController {
    
   
}


public class VerfiyCodeRender{
    
    private init() {
        
    }
    public static let renderInstance = VerfiyCodeRender()
    public func generateVerfiyCode(_ seed:String = "1234567890", codeLenght maxLength: Int = 6)-> String{
        var verfiyCode = ""
        for _ in 0 ... ( (maxLength > seed.count ? seed.count : maxLength) - 1 ) {
            let index =     arc4random_uniform(UInt32(maxLength))
            verfiyCode.append( seed[seed.index(seed.startIndex, offsetBy: index)])
        }
        return verfiyCode
    }
    var  `default`: String{
        return generateVerfiyCode()
    }
    
}
