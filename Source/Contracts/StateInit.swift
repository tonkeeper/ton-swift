import Foundation
import BigInt

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L141
// _ split_depth:(Maybe (## 5)) special:(Maybe TickTock)
//  code:(Maybe ^Cell) data:(Maybe ^Cell)
//  library:(HashmapE 256 SimpleLib) = StateInit;

public struct StateInit: Writable, Readable {
    var splitDepth: UInt32?
    var special: TickTock?
    var code: Cell?
    var data: Cell?
    var libraries: Dictionary<BigUInt, SimpleLibrary>?

    init(splitDepth: UInt32? = nil, special: TickTock? = nil, code: Cell? = nil, data: Cell? = nil, libraries: Dictionary<BigUInt, SimpleLibrary>? = nil) {
        self.splitDepth = splitDepth;
        self.special = special;
        self.code = code;
        self.data = data;
        self.libraries = libraries;
    }
    
    public func writeTo(builder: Builder) throws {
        if let splitDepth = self.splitDepth {
            try builder.storeBit(true)
            try builder.storeUint(UInt64(splitDepth), bits: 5)
        } else {
            try builder.storeBit(false)
        }
        
        if let ticktock = self.special {
            try builder.storeBit(true)
            try builder.store(ticktock)
        } else {
            try builder.storeBit(false)
        }
        
        try builder.storeMaybeRef(cell: self.code)
        try builder.storeMaybeRef(cell: self.data)
        try builder.storeDict(dict: self.libraries)
    }
    
    static public func readFrom(slice: Slice) throws -> StateInit {
        let splitDepth: UInt32? = try slice.loadMaybe { s in
            UInt32(try s.loadUint(bits: 5))
        };

        let special: TickTock? = try slice.loadMaybe { s in
            try TickTock.readFrom(slice: slice)
        };

        let code = try slice.loadMaybeRef()
        let data = try slice.loadMaybeRef()
        
        let libraries: Dictionary<BigUInt, SimpleLibrary> = try slice.loadDict(key: DictionaryKeys.BigUint(bits: 256), value: SimpleLibraryValue())
        
        return StateInit(splitDepth: splitDepth, special: special, code: code, data: data, libraries: libraries)
    }
}

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
// tick_tock$_ tick:Bool tock:Bool = TickTock;

struct TickTock: Writable, Readable {
    var tick: Bool
    var tock: Bool
    
    func writeTo(builder: Builder) throws {
        try builder.storeBit(self.tick)
        try builder.storeBit(self.tock)
    }
    
    static func readFrom(slice: Slice) throws -> TickTock {
        return TickTock(
            tick: try slice.loadBit(),
            tock: try slice.loadBit()
        )
    }
}
