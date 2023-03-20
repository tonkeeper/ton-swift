import Foundation

/*
 Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L151
 message$_ {X:Type} info:CommonMsgInfoRelaxed
                    init:(Maybe (Either StateInit ^StateInit))
                    body:(Either X ^X) = MessageRelaxed X;
 */

public struct MessageRelaxed: Readable, Writable {
    public let info: CommonMessageInfoRelaxed
    public let stateInit: StateInit?
    public let body: Cell
    
    public static func readFrom(slice: Slice) throws -> MessageRelaxed {
        let info = try CommonMessageInfoRelaxed.readFrom(slice: slice)
            
        var stateInit: StateInit? = nil
        if try slice.bits.loadBit() {
            if !(try slice.bits.loadBit()) {
                stateInit = try StateInit.readFrom(slice: slice)
            } else {
                stateInit = try StateInit.readFrom(slice: try slice.loadRef().beginParse())
            }
        }
        
        var body: Cell
        if try slice.bits.loadBit() {
            body = try slice.loadRef()
        } else {
            body = try slice.loadRemainder()
        }
        
        return MessageRelaxed(info: info, stateInit: stateInit, body: body)
    }
    
    public func writeTo(builder: Builder) throws {
        try builder.store(info)
        
        if let stateInit {
            try builder.bits.write(bit: true)
            let initCell = try Builder().store(stateInit)
            
            if builder.availableBits - 2 /* At least on byte for body */ >= initCell.bitsCount {
                try builder.bits.write(bit: false)
                try builder.store(initCell)
            } else {
                try builder.bits.write(bit: true)
                try builder.storeRef(cell: initCell)
            }
        } else {
            try builder.bits.write(bit: false)
        }
        
        if builder.availableBits - 1 /* At least on byte for body */ >= body.bits.length {
            try builder.bits.write(bit: false)
            try builder.store(body.asBuilder())
        } else {
            try builder.bits.write(bit: true)
            try builder.storeRef(cell: body)
        }
    }
}
