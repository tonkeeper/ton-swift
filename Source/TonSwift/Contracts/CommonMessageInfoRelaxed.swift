import Foundation

/*
 Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L132
 int_msg_info$0 ihr_disabled:Bool
                bounce:Bool
                bounced:Bool
                src:MsgAddress
                dest:MsgAddressInt
                value:CurrencyCollection
                ihr_fee:Grams
                fwd_fee:Grams
                created_lt:uint64
                created_at:uint32 = CommonMsgInfoRelaxed;
 
 
 
 
 ext_out_msg_info$11 src:MsgAddress
                     dest:MsgAddressExt
                     created_lt:uint64
                     created_at:uint32 = CommonMsgInfoRelaxed;
 */

public struct CommonMessageInfoRelaxedInternal {
    let ihrDisabled: Bool
    let bounce: Bool
    let bounced: Bool
    let src: AnyAddress
    let dest: Address
    let value: CurrencyCollection
    let ihrFee: Coins
    let forwardFee: Coins
    let createdLt: UInt64
    let createdAt: UInt32
}

public struct CommonMessageInfoRelaxedExternalOut {
    let src: AnyAddress
    let dest: ExternalAddress?
    let createdLt: UInt64
    let createdAt: UInt32
}

public enum CommonMessageInfoRelaxed: CellLoadable, CellStorable {
    case internalInfo(info: CommonMessageInfoRelaxedInternal)
    case externalOutInfo(info: CommonMessageInfoRelaxedExternalOut)
    
    public static func readFrom(slice: Slice) throws -> CommonMessageInfoRelaxed {
        // Internal message
        if !(try slice.loadBit()) {
            let ihrDisabled = try slice.loadBit()
            let bounce = try slice.loadBit()
            let bounced = try slice.loadBit()
            let src: AnyAddress = try slice.loadType()
            let dest: Address = try slice.loadType()
            let value: CurrencyCollection = try slice.loadType()
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMessageInfoRelaxed.internalInfo(
                info: .init(
                    ihrDisabled: ihrDisabled,
                    bounce: bounce,
                    bounced: bounced,
                    src: src,
                    dest: dest,
                    value: value,
                    ihrFee: ihrFee,
                    forwardFee: forwardFee,
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
        
        // External In message
        if !(try slice.loadBit()) {
            throw TonError.custom("External In message is not possible for CommonMessageInfoRelaxed")
        } else {
            // External Out mesage
            let src: AnyAddress = try slice.loadType()
            let dest: AnyAddress = try slice.loadType()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMessageInfoRelaxed.externalOutInfo(
                info: .init(
                    src: src,
                    dest: try dest.asExternal(),
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
    }
    
    public func writeTo(builder: Builder) throws {
        switch self {
        case .internalInfo(let info):
            try builder.write(bit: false)
            try builder.write(bit: info.ihrDisabled)
            try builder.write(bit: info.bounce)
            try builder.write(bit: info.bounced)
            try builder.store(info.src)
            try builder.store(AnyAddress(info.dest))
            try builder.store(info.value)
            try builder.storeCoins(info.ihrFee)
            try builder.storeCoins(info.forwardFee)
            try builder.write(uint: info.createdLt, bits: 64)
            try builder.write(uint: UInt64(info.createdAt), bits: 32)
            
        case .externalOutInfo(let info):
            try builder.write(bit:true)
            try builder.write(bit:true)
            try builder.store(info.src)
            try builder.store(AnyAddress(info.dest))
            try builder.write(uint: info.createdLt, bits: 64)
            try builder.write(uint: UInt64(info.createdAt), bits: 32)
        }
    }
}
