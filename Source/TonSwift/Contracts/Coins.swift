import Foundation
import BigInt

/// 128-bit integer representing base TON currency: toncoins (aka `grams` in block.tlb).
public struct Coins {
    var amount: BigUInt
    
    init(_ a: some BinaryInteger) {
        // we use signed integer here because of `0` literal is a signed Int.
        amount = BigUInt(a)
    }
}

extension Coins: RawRepresentable {
    public typealias RawValue = BigUInt

    public init?(rawValue: BigUInt) {
        amount = rawValue
    }

    public var rawValue: BigUInt {
        amount
    }
}

extension Coins: CellCodable {
    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: amount, limit: 16)
    }
    public static func loadFrom(slice: Slice) throws -> Coins {
        Coins(try slice.loadVarUintBig(limit: 16))
    }
}

extension Slice {
    /// Loads Coins value
    public func loadCoins() throws -> Coins {
        try loadType()
    }
    
    /// Preloads Coins value
    public func preloadCoins() throws -> Coins {
        try preloadType()
    }
    
    /// Load optionals Coins value.
    public func loadMaybeCoins() throws -> Coins? {
        try loadBoolean() ? try loadCoins() : nil
    }
}

extension Builder {
    
    /// Write coins amount in varuint format
    @discardableResult
    func store(coins: Coins) throws -> Self {
        try store(varuint: coins.amount, limit: 16)
    }
    
    /**
     * Store optional coins value
     * @param amount amount of coins, null or undefined
     * @returns this builder
     */
    @discardableResult
    public func storeMaybe(coins: Coins?) throws -> Self {
        if let coins {
            try store(bit: true)
            try store(coins: coins)
        } else {
            try store(bit: false)
        }
        return self
    }

}
