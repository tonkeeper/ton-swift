//
//  CompactAddress.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import Foundation

/// The most compact address encoding that's often used within smart contracts: workchain + hash.
public struct CompactAddress: Hashable, CellCodable, StaticSize {
    public static var bitWidth: Int = 8 + 256
    public let inner: Address
    
    init(_ inner: Address) {
        self.inner = inner
    }
    
    public func storeTo(builder: Builder) throws {
        try builder
            .store(int: inner.workchain, bits: 8)
            .store(data: inner.hash)
    }
    
    public static func loadFrom(slice: Slice) throws -> CompactAddress {
        try slice.tryLoad { s in
            let wc = Int8(try s.loadInt(bits: 8))
            let hash = try s.loadBytes(32)
            return CompactAddress(Address(workchain: wc, hash: hash))
        }
    }
}
