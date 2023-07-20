//
//  DefaultCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public class DefaultCoder<X: CellCodable>: TypeCoder {
    public typealias T = X

    public func storeValue(_ src: T, to builder: Builder) throws {
        try src.storeTo(builder: builder)
    }

    public func loadValue(from src: Slice) throws -> T {
        try T.loadFrom(slice: src)
    }
}
