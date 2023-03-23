import Foundation

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L145
// simple_lib$_ public:Bool root:^Cell = SimpleLib;

public struct SimpleLibrary: Hashable {
    var `public`: Bool
    var root: Cell
}

public func loadSimpleLibrary(slice: Slice) throws -> SimpleLibrary {
    return SimpleLibrary(
        public: try slice.bits.loadBit(),
        root: try slice.loadRef()
    )
}

public func storeSimpleLibrary(src: SimpleLibrary, builder: Builder) throws {
    try builder.bits.write(bit: src.public)
    try builder.storeRef(cell: src.root)
}

public struct SimpleLibraryValue: TypeCoder {
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? SimpleLibrary else {
            throw TonError.custom("Wrong src type. Expected simple library")
        }
        
        try storeSimpleLibrary(src: src, builder: builder)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try loadSimpleLibrary(slice: src)
    }
}
