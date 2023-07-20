//
//  Set+CellCodableDictionary.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Set: CellCodableDictionary where Element: CellCodable & StaticSize {
    public static func loadRootFrom(slice: Slice) throws -> Self {
        let dict: [Element: Empty] = try DictionaryCoder.default().loadRoot(slice)
        return Set(dict.keys)
    }
    public func storeRootTo(builder: Builder) throws {
        let dict: [Element: Empty] = Dictionary(uniqueKeysWithValues: map { k in (k, Empty()) })
        try DictionaryCoder.default().storeRoot(map: dict, builder: builder)
    }
}
