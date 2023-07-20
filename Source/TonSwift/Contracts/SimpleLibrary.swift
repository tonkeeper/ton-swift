//
//  File.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L145
// simple_lib$_ public:Bool root:^Cell = SimpleLib;

public struct SimpleLibrary: Hashable, CellCodable {
    var `public`: Bool
    var root: Cell

    // MARK: CellCodable

    public func storeTo(builder: Builder) throws {
        try builder.store(bit: self.public)
            .store(ref: root)
    }
    public static func loadFrom(slice: Slice) throws -> SimpleLibrary {
        Self(
            public: try slice.loadBoolean(),
            root: try slice.loadRef()
        )
    }
}
