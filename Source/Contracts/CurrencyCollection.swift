import Foundation
import BigInt

/// Implements CurrencyCollection per TLB schema:
///
/// ```
/// extra_currencies$_ dict:(HashmapE 32 (VarUInteger 32)) = ExtraCurrencyCollection;
/// currencies$_ grams:Grams other:ExtraCurrencyCollection = CurrencyCollection;
/// ```
struct CurrencyCollection: Readable, Writable {
    let other: Dictionary<Int, BigUInt>?
    let coins: Coins
    
    static func readFrom(slice: Slice) throws -> CurrencyCollection {
        let coins = try slice.loadCoins()
        let other: Dictionary<Int, BigUInt> = try slice.loadDict(
            key: DictionaryKeys.Uint(bits: 32),
            value: DictionaryValues.BigVarUint(bits: (5 /* log2(32) */))
        )
        
        return CurrencyCollection(other: other, coins: coins)
    }
    
    func writeTo(builder: Builder) throws {
        try builder.storeCoins(coins: coins)
        try builder.storeDict(dict: other)
    }
}
