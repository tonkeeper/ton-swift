//
//  CellCodableDictionary.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Type of a standard dictionary where keys have a statically known length.
/// To work with dynamically known key lengths, use `DictionaryCoder` to load and store dictionaries.
public protocol CellCodableDictionary: CellCodable {
    func storeRootTo(builder: Builder) throws
    static func loadRootFrom(slice: Slice) throws -> Self
}
