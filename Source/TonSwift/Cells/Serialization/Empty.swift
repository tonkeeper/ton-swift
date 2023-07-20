//
//  Empty.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Empty struct to store empty leafs in the dictionaries to form sets.
public struct Empty: CellCodable {
    public static func loadFrom(slice: Slice) throws -> Self {
        Empty()
    }
    public func storeTo(builder: Builder) throws {
        // store nothing
    }
}
