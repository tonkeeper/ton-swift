import Foundation

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
// tick_tock$_ tick:Bool tock:Bool = TickTock;

struct TickTock {
    var tick: Bool
    var tock: Bool
}

func loadTickTock(slice: Slice) throws -> TickTock {
    return TickTock(
        tick: try slice.loadBit(),
        tock: try slice.loadBit()
    )
}

func storeTickTock(src: TickTock) -> (Builder) throws -> Void {
    return { builder in
        try builder.storeBit(src.tick)
        try builder.storeBit(src.tock)
    }
}
