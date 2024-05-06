import Foundation
import BigInt

public struct StonfiSwapData: CellCodable {
    public let assetToSwap: Address
    public let minAskAmount: BigUInt
    public let userWalletAddress: Address
    public let referralAddress: Address?

    public func storeTo(builder: Builder) throws {
        try builder.store(uint: OpCodes.STONFI_SWAP, bits: 32)
        try builder.store(AnyAddress(assetToSwap))
        try builder.store(coins: Coins(minAskAmount.magnitude))
        try builder.store(AnyAddress(userWalletAddress))

        if referralAddress != nil {
            try builder.store(bit: true)
            try builder.store(AnyAddress(referralAddress))
        } else {
            try builder.store(bit: false)
        }
    }
    
    public static func loadFrom(slice: Slice) throws -> StonfiSwapData {
        _ = try slice.loadUint(bits: 32)
        let assetToSwap: Address = try slice.loadType()
        let minAskAmount = try slice.loadCoins().amount
        
        let userWalletAddress: Address = try slice.loadType()
        let referralAddress: Address? = try slice.loadType()

                
        return StonfiSwapData(assetToSwap: assetToSwap, minAskAmount: minAskAmount, userWalletAddress: userWalletAddress, referralAddress: referralAddress)
    }
}
