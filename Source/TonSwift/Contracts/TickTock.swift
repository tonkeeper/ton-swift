//
//  TickTock.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
// tick_tock$_ tick:Bool tock:Bool = TickTock;

struct TickTock: CellCodable {
    var tick: Bool
    var tock: Bool
    
    func storeTo(builder: Builder) throws {
        try builder.store(bit: tick)
            .store(bit: tock)
    }
    
    static func loadFrom(slice: Slice) throws -> TickTock {
        TickTock(
            tick: try slice.loadBoolean(),
            tock: try slice.loadBoolean()
        )
    }
}
