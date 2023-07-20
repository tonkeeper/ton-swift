//
//  Bool+CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Bool: CellCodable, StaticSize {
    public static var bitWidth = 1

    public func storeTo(builder: Builder) throws {
        try builder.store(bit: self)
    }

    public static func loadFrom(slice: Slice) throws -> Self {
        try slice.loadBoolean()
    }
}
