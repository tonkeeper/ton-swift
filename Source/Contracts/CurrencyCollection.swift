import Foundation
import BigInt

struct CurrencyCollection {
    let other: Dictionary<Int, BigUInt>?
    let coins: Coins
}

func loadCurrencyCollection(slice: Slice) throws -> CurrencyCollection {
    let coins = try slice.loadCoins()
    let other: Dictionary<Int, BigUInt> = try slice.loadDict(
        key: DictionaryKeys.Uint(bits: 32),
        value: DictionaryValues.BigVarUint(bits: (5 /* log2(32) */))
    )
    
    if other.size == 0 {
        return CurrencyCollection(other: nil, coins: coins)
    } else {
        return CurrencyCollection(other: other, coins: coins)
    }
}

func storeCurrencyCollection(collection: CurrencyCollection, builder: Builder) throws -> Builder {
    try builder.storeCoins(coins: collection.coins)
    if let other = collection.other {
        try builder.storeDict(dict: other)
    } else {
        try builder.storeBit(false)
    }
    
    return builder
}
