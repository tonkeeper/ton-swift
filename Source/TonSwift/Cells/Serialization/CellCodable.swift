//
//  CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Types implementing both reading and writing
public protocol CellCodable {
    func storeTo(builder: Builder) throws
    static func loadFrom(slice: Slice) throws -> Self
}

extension CellCodable {
    static func defaultCoder() -> some TypeCoder {
        DefaultCoder<Self>()
    }
}
