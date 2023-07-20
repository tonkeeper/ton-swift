//
//  Set+CellCodable.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Set: CellCodable where Element: CellCodable & StaticSize {
    public static func loadFrom(slice: Slice) throws -> Self {
        let dict: [Element: Empty] = try DictionaryCoder.default().load(slice)
        return Set(dict.keys)
    }
    public func storeTo(builder: Builder) throws {
        let dict: [Element: Empty] = Dictionary(uniqueKeysWithValues: map { k in (k, Empty()) })
        try DictionaryCoder.default().store(map: dict, builder: builder)
    }
}
