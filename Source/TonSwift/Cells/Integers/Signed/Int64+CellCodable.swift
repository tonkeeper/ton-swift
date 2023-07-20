//
//  Int64+CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Int64: CellCodable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func storeTo(builder: Builder) throws {
        try builder.store(int: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        Self(try slice.loadInt(bits: Self.bitWidth))
    }
}
