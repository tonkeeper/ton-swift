//
//  IntCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

public struct IntCoder: TypeCoder {
    public typealias T = BigInt
    
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(int: src, bits: bits)
    }
    
    public func loadValue(from src: Slice) throws -> T {
        try src.loadIntBig(bits: bits)
    }
}
