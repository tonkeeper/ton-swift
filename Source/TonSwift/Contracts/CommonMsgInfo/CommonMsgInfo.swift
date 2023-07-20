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

public enum CommonMsgInfo: CellCodable {
    case internalInfo(info: CommonMsgInfoInternal)
    case externalOutInfo(info: CommonMsgInfoExternalOut)
    case externalInInfo(info: CommonMsgInfoExternalIn)
    
    public static func loadFrom(slice: Slice) throws -> CommonMsgInfo {
        // Internal message
        if !(try slice.loadBoolean()) {
            let ihrDisabled = try slice.loadBoolean()
            let bounce = try slice.loadBoolean()
            let bounced = try slice.loadBoolean()
            let src: Address = try slice.loadType()
            let dest: Address = try slice.loadType()
            let value: CurrencyCollection = try slice.loadType()
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMsgInfo.internalInfo(
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
        if !(try slice.loadBoolean()) {
            let src: AnyAddress = try slice.loadType()
            let dest: Address = try slice.loadType()
            let importFee = try slice.loadCoins()
            
            return CommonMsgInfo.externalInInfo(
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
            
            return CommonMsgInfo.externalOutInfo(
                info: .init(
                    src: src,
                    dest: try dest.asExternal(),
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
    }
    
    public func storeTo(builder: Builder) throws {
        switch self {
        case .internalInfo(let info):
            try builder.store(bit: 0)
                .store(bit: info.ihrDisabled)
                .store(bit: info.bounce)
                .store(bit: info.bounced)
                .store(AnyAddress(info.src))
                .store(AnyAddress(info.dest))
                .store(info.value)
                .store(coins: info.ihrFee)
                .store(coins: info.forwardFee)
                .store(uint: info.createdLt, bits: 64)
                .store(uint: UInt64(info.createdAt), bits: 32)
            
        case .externalOutInfo(let info):
            try builder.store(bit: 1)
                .store(bit: 1)
                .store(AnyAddress(info.src))
                .store(AnyAddress(info.dest))
                .store(uint: info.createdLt, bits: 64)
                .store(uint: UInt64(info.createdAt), bits: 32)
            
        case .externalInInfo(let info):
            try builder.store(bit: true)
                .store(bit: false)
                .store(AnyAddress(info.src))
                .store(AnyAddress(info.dest))
                .store(coins: info.importFee)
        }
    }
}
