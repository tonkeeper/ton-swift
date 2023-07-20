//
//  Dictionary+CellCodableDictionary.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Dictionary: CellCodableDictionary where Key: CellCodable & StaticSize, Value: CellCodable {
    public func storeRootTo(builder: Builder) throws {
        try DictionaryCoder.default().storeRoot(map: self, builder: builder)
    }
    
    public static func loadRootFrom(slice: Slice) throws -> Self {
        try DictionaryCoder.default().loadRoot(slice)
    }
}
