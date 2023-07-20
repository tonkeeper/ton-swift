//
//  VarUInt120.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

/// Up-to-15-byte (120-bit) unsigned integer (4-bit length prefix)
public struct VarUInt120: Hashable, CellCodable {
    public var value: BigUInt
    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: value, limit: 16)
    }
    public static func loadFrom(slice: Slice) throws -> Self {
        Self(value: try slice.loadVarUintBig(limit: 16))
    }
}
