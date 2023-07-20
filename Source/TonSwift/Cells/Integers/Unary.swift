//
//  Unary.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Represents unary integer encoding: `0` for 0, `10` for 1, `110` for 2, `1{n}0` for n.
public struct Unary: CellCodable {
    public let value: Int
    
    init(_ v: Int) {
        value = v
    }
    
    public func storeTo(builder: Builder) throws {
        try builder.store(bit: 1, repeat: value)
        try builder.store(bit: 0)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        var v: Int = 0
        while try slice.loadBit() == 1 {
            v += 1
        }
        return Unary(v)
    }
}
