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
    var libraries: [UInt256: SimpleLibrary]

    init(splitDepth: UInt32? = nil,
         special: TickTock? = nil,
         code: Cell? = nil,
         data: Cell? = nil,
         libraries: [UInt256: SimpleLibrary] = [:]) {
        self.splitDepth = splitDepth;
        self.special = special;
        self.code = code;
        self.data = data;
        self.libraries = libraries;
    }
    
    public func writeTo(builder: Builder) throws {
        if let splitDepth = self.splitDepth {
            try builder.write(bit: true)
            try builder.storeUint(UInt64(splitDepth), bits: 5)
        } else {
            try builder.write(bit: false)
        }
        
        if let ticktock = self.special {
            try builder.write(bit: true)
            try builder.store(ticktock)
        } else {
            try builder.write(bit: false)
        }
        
        try builder.storeMaybeRef(cell: self.code)
        try builder.storeMaybeRef(cell: self.data)
        try builder.store(self.libraries)
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
        
        let libraries: [UInt256: SimpleLibrary] = try slice.loadType()
        
        return StateInit(splitDepth: splitDepth, special: special, code: code, data: data, libraries: libraries)
    }
}

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
// tick_tock$_ tick:Bool tock:Bool = TickTock;

struct TickTock: Writable, Readable {
    var tick: Bool
    var tock: Bool
    
    func writeTo(builder: Builder) throws {
        try builder.write(bit: self.tick)
        try builder.write(bit: self.tock)
    }
    
    static func readFrom(slice: Slice) throws -> TickTock {
        return TickTock(
            tick: try slice.loadBit(),
            tock: try slice.loadBit()
        )
    }
}

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L145
// simple_lib$_ public:Bool root:^Cell = SimpleLib;

public struct SimpleLibrary: Hashable {
    var `public`: Bool
    var root: Cell
}

extension SimpleLibrary: Codeable {
    public func writeTo(builder: Builder) throws {
        try builder.write(bit: self.public)
        try builder.storeRef(cell: self.root)
    }
    public static func readFrom(slice: Slice) throws -> SimpleLibrary {
        return Self(
            public: try slice.loadBit(),
            root: try slice.loadRef()
        )
    }
}
