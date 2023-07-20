//
//  UInt256.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

/// 256-bit unsigned integer
public struct UInt256: Hashable, CellCodable, StaticSize {
    public var value: BigUInt

    public static var bitWidth: Int = 256

    init(biguint: BigUInt) {
        value = biguint
    }

    public func storeTo(builder: Builder) throws {
        try builder.store(uint: value, bits: Self.bitWidth)
    }

    public static func loadFrom(slice: Slice) throws -> Self {
        Self(biguint: try slice.loadUintBig(bits: Self.bitWidth))
    }
}
