import Foundation
import BigInt

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L141
// _ split_depth:(Maybe (## 5)) special:(Maybe TickTock)
//  code:(Maybe ^Cell) data:(Maybe ^Cell)
//  library:(HashmapE 256 SimpleLib) = StateInit;

struct StateInit: CellWritable {
    var splitDepth: UInt32?
    var special: TickTock?
    var code: Cell?
    var data: Cell?
    var libraries: Dictionary<BigUInt, SimpleLibrary>?
    
    func writeTo(builder: Builder) throws {
        if let splitDepth = self.splitDepth {
            try builder.storeBit(true)
            try builder.storeUint(splitDepth, bits: 5)
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
}

func loadStateInit(slice: Slice) throws -> StateInit {
    var splitDepth: UInt32?
    if try slice.loadBit() {
        splitDepth = try slice.loadUint(bits: 5)
    }
    
    var special: TickTock?
    if try slice.loadBit() {
        special = try loadTickTock(slice: slice)
    }
    
    let code = try slice.loadMaybeRef()
    let data = try slice.loadMaybeRef()
    
    let libraries: Dictionary<BigUInt, SimpleLibrary> = try slice.loadDict(key: DictionaryKeys.BigUint(bits: 256), value: SimpleLibraryValue())
    
    return StateInit(splitDepth: splitDepth, special: special, code: code, data: data, libraries: libraries)
}
