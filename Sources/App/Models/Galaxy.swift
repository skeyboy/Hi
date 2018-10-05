//
//  Galaxy.swift
//  Hello
//
//  Created by sk on 2018/9/30.
//

import FluentSQLite
import Vapor
import SQLite

struct Galaxy: SQLiteModel {
    var id:Int? = nil
    var name: String
}
struct Planet: SQLiteModel {
    var id: Int?
    var name: String
    var galaxyID: Int
}
extension Galaxy{
    var planets: Children<Galaxy, Planet>{
        return children(\.galaxyID)
    }
}

extension Planet{
    var galaxy: Parent<Planet, Galaxy>{
        return parent(\.galaxyID)
    }
}
/*
var galaxy: Galaxy?
galaxy?.planets.query(on: <#T##DatabaseConnectable#>)
var planet: Planet?
planet!.galaxy.get(on: <#T##DatabaseConnectable#>)
*/

struct Tag: SQLiteModel {
    var id: Int?
    
    var name: String
}
struct PlanetTag: SQLitePivot {
    static var leftIDKey: WritableKeyPath<PlanetTag, Int> = \.planetID
    
    static var rightIDKey: WritableKeyPath<PlanetTag, Int> = \.tagID
    
    typealias Left = Planet
    
    typealias Right = Tag
    
    var id: Int?
    var planetID: Int
    var tagID: Int
}

extension Planet{
    var tags: Siblings<Planet, Tag, PlanetTag>{
        return siblings()
    }
    
}

extension Tag{
    var planets: Siblings<Tag, Planet, PlanetTag>{
        return siblings()
    }
}
/*
var p: Planet?
p?.tags.query(on: <#T##DatabaseConnectable#>)
var tag: Tag?
tag?.planets.query(on: <#T##DatabaseConnectable#>)
*/

extension PlanetTag: ModifiablePivot{
    init(_ left: Planet, _ right: Tag) throws {
        planetID = try left.requireID()
        tagID = try right.requireID()
    }
}

/*
var pm: Planet?
var tm: Tag?
pm?.tags.attach(tm, on: <#T##DatabaseConnectable#>)
pm?.tags.detach(tm, on: <#T##DatabaseConnectable#>)
*/

typealias All = Migration&Content&Parameter


extension Galaxy: Migration{}
extension Galaxy: Content{}
extension Galaxy: Parameter{}

extension PlanetTag: All{}
extension Planet: All{}
extension Tag:All{}

