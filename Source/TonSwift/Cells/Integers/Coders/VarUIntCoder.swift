//
//  VarUIntCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

/// Encodes variable-length integers using `limit` bound on integer size in _bytes_.
/// Therefore, `VarUIntCoder(32)` can represent 248-bit integers (lengths 0...31 bytes).
/// TL-B:
/// ```
/// var_uint$_ {n:#} len:(#< n) value:(uint (len * 8)) = VarUInteger n;
/// var_int$_  {n:#} len:(#< n) value:(int (len * 8))  = VarInteger n;
/// ```
public struct VarUIntCoder: TypeCoder {
    public typealias T = BigUInt
    
    public let limit: Int
    
    public init(limit: Int) {
        self.limit = limit
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(varuint: src, limit: limit)
    }
    
    public func loadValue(from src: Slice) throws -> T {
        try src.loadVarUintBig(limit: limit)
    }
}
