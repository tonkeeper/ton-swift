//
//  UInt8+CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension UInt8: CellCodable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        Self(try slice.loadUint(bits: Self.bitWidth))
    }
}
