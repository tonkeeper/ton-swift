import Foundation
import BigInt

/// Implements CurrencyCollection per TLB schema:
///
/// ```
/// extra_currencies$_ dict:(HashmapE 32 (VarUInteger 32)) = ExtraCurrencyCollection;
/// currencies$_ grams:Grams other:ExtraCurrencyCollection = CurrencyCollection;
/// ```
struct CurrencyCollection: Codeable {
    let coins: Coins
    let other: Dictionary<UInt32, VarUInt248>
    
    init(coins: Coins, other: Dictionary<UInt32, VarUInt248> = .empty()) {
        self.coins = coins
        self.other = other
    }
    
    static func readFrom(slice: Slice) throws -> CurrencyCollection {
        let coins = try slice.loadCoins()
        let other: Dictionary<UInt32, VarUInt248> = try slice.loadType()
        return CurrencyCollection(coins: coins, other: other)
    }
    
    func writeTo(builder: Builder) throws {
        try builder.storeCoins(coins: coins)
        try builder.store(other)
    }
}
