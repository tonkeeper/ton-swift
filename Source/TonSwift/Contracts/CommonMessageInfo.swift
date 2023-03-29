import Foundation

/*
 Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L123
 int_msg_info$0 ihr_disabled:Bool
                bounce:Bool
                bounced:Bool
                src:MsgAddressInt
                dest:MsgAddressInt
                value:CurrencyCollection
                ihr_fee:Grams
                fwd_fee:Grams
                created_lt:uint64
                created_at:uint32 = CommonMsgInfo;
 
 ext_in_msg_info$10 src:MsgAddressExt
                    dest:MsgAddressInt
                    import_fee:Grams = CommonMsgInfo;
 ext_out_msg_info$11 src:MsgAddressInt
                     dest:MsgAddressExt
                     created_lt:uint64
                     created_at:uint32 = CommonMsgInfo;
 */

public struct CommonMessageInfoInternal {
    let ihrDisabled: Bool
    let bounce: Bool
    let bounced: Bool
    let src: Address
    let dest: Address
    let value: CurrencyCollection
    let ihrFee: Coins
    let forwardFee: Coins
    let createdLt: UInt64
    let createdAt: UInt32
}

public struct CommonMessageInfoExternalIn {
    let src: ExternalAddress?
    let dest: Address
    let importFee: Coins
}

public struct CommonMessageInfoExternalOut {
    let src: Address
    let dest: ExternalAddress?
    let createdLt: UInt64
    let createdAt: UInt32
}

public enum CommonMessageInfo: Readable, Writable {
    case internalInfo(info: CommonMessageInfoInternal)
    case externalOutInfo(info: CommonMessageInfoExternalOut)
    case externalInInfo(info: CommonMessageInfoExternalIn)
    
    public static func readFrom(slice: Slice) throws -> CommonMessageInfo {
        // Internal message
        if !(try slice.loadBit()) {
            let ihrDisabled = try slice.loadBit()
            let bounce = try slice.loadBit()
            let bounced = try slice.loadBit()
            let src: Address = try slice.loadType()
            let dest: Address = try slice.loadType()
            let value: CurrencyCollection = try slice.loadType()
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMessageInfo.internalInfo(
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
            let src: AnyAddress = try slice.loadType()
            let dest: Address = try slice.loadType()
            let importFee = try slice.loadCoins()
            
            return CommonMessageInfo.externalInInfo(
                info: .init(
                    src: try src.asExternal(),
                    dest: dest,
                    importFee: importFee
                )
            )
        } else {
            // External Out mesage
            let src: Address = try slice.loadType()
            let dest: AnyAddress = try slice.loadType()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMessageInfo.externalOutInfo(
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
            try builder.bits.write(bit: false)
            try builder.bits.write(bit: info.ihrDisabled)
            try builder.bits.write(bit: info.bounce)
            try builder.bits.write(bit: info.bounced)
            try builder.store(AnyAddress(info.src))
            try builder.store(AnyAddress(info.dest))
            try builder.store(info.value)
            try builder.storeCoins(coins: info.ihrFee)
            try builder.storeCoins(coins: info.forwardFee)
            try builder.storeUint(info.createdLt, bits: 64)
            try builder.storeUint(UInt64(info.createdAt), bits: 32)
            
        case .externalOutInfo(let info):
            try builder.bits.write(bit: true)
            try builder.bits.write(bit: true)
            try builder.store(AnyAddress(info.src))
            try builder.store(AnyAddress(info.dest))
            try builder.storeUint(info.createdLt, bits: 64)
            try builder.storeUint(UInt64(info.createdAt), bits: 32)
            
        case .externalInInfo(let info):
            try builder.bits.write(bit: true)
            try builder.bits.write(bit: false)
            try builder.store(AnyAddress(info.src))
            try builder.store(AnyAddress(info.dest))
            try builder.storeCoins(coins: info.importFee)
        }
    }
}
