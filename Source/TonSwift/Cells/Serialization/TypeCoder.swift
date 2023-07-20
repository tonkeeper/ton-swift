//
//  TypeCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Every type that can be used as a dictionary value has an accompanying coder object configured to read that type.
/// This protocol allows implement dependent types because the exact instance would have runtime parameter such as bitlength for the values of this type.
public protocol TypeCoder {
    associatedtype T
    func storeValue(_ src: T, to builder: Builder) throws
    func loadValue(from src: Slice) throws -> T
}

public extension TypeCoder {
    /// Serializes type to Cell
    func serializeToCell(_ src: T) throws -> Cell {
        let builder = Builder()
        try storeValue(src, to: builder)
        return try builder.endCell()
    }
}
