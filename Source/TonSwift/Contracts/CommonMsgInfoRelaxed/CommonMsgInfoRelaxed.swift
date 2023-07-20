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

public enum CommonMsgInfoRelaxed: CellCodable {
    case internalInfo(info: CommonMsgInfoRelaxedInternal)
    case externalOutInfo(info: CommonMsgInfoRelaxedExternalOut)
    
    public static func loadFrom(slice: Slice) throws -> CommonMsgInfoRelaxed {
        // Internal message
        if !(try slice.loadBoolean()) {
            let ihrDisabled = try slice.loadBoolean()
            let bounce = try slice.loadBoolean()
            let bounced = try slice.loadBoolean()
            let src: AnyAddress = try slice.loadType()
            let dest: Address = try slice.loadType()
            let value: CurrencyCollection = try slice.loadType()
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMsgInfoRelaxed.internalInfo(
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
            throw TonError.custom("External In message is not possible for CommonMessageInfoRelaxed")
        } else {
            // External Out mesage
            let src: AnyAddress = try slice.loadType()
            let dest: AnyAddress = try slice.loadType()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMsgInfoRelaxed.externalOutInfo(
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
            try builder.store(bit: false)
                .store(bit: info.ihrDisabled)
                .store(bit: info.bounce)
                .store(bit: info.bounced)
                .store(info.src)
                .store(AnyAddress(info.dest))
                .store(info.value)
                .store(coins: info.ihrFee)
                .store(coins: info.forwardFee)
                .store(uint: info.createdLt, bits: 64)
                .store(uint: UInt64(info.createdAt), bits: 32)
            
        case .externalOutInfo(let info):
            try builder.store(bit:true)
                .store(bit:true)
                .store(info.src)
                .store(AnyAddress(info.dest))
                .store(uint: info.createdLt, bits: 64)
                .store(uint: UInt64(info.createdAt), bits: 32)
        }
    }
}
