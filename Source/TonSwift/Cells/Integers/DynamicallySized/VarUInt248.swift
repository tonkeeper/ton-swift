//
//  VarUInt248.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

/// Up-to-31-byte (248-bit) unsigned integer (5-bit length prefix)
public struct VarUInt248: Hashable, CellCodable {
    public var value: BigUInt
    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: value, limit: 32)
    }
    public static func loadFrom(slice: Slice) throws -> Self {
        Self(value: try slice.loadVarUintBig(limit: 32))
    }
}
