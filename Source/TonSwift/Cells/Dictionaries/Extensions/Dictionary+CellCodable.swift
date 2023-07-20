//
//  Dictionary+CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Dictionary: CellCodable where Key: CellCodable & StaticSize, Value: CellCodable {
    public static func loadFrom(slice: Slice) throws -> Self {
        try DictionaryCoder.default().load(slice)
    }
    public func storeTo(builder: Builder) throws {
        try DictionaryCoder.default().store(map: self, builder: builder)
    }
}
