import Foundation
import BigInt

/// 128-bit integer representing base TON currency: toncoins (aka `grams` in block.tlb).
public struct Coins {
    var amount: BigUInt
    
    init(_ a: some BinaryInteger) {
        // we use signed integer here because of `0` literal is a signed Int.
        self.amount = BigUInt(a)
    }
}

extension Coins: RawRepresentable {
    public typealias RawValue = BigUInt;

    public init?(rawValue: BigUInt) {
        self.amount = rawValue
    }

    public var rawValue: BigUInt {
        return self.amount
    }
}

extension Coins: Codeable {
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: self.amount, bits: 4)
    }
    public static func readFrom(slice: Slice) throws -> Coins {
        return Coins(try slice.loadVarUintBig(bits: 4))
    }
}

extension Slice {
    /// Loads Coins value
    public func loadCoins() throws -> Coins {
        return try loadType()
    }
    
    /// Preloads Coins value
    public func preloadCoins() throws -> Coins {
        return try preloadType()
    }
    
    /// Load optionals Coins value.
    public func loadMaybeCoins() throws -> Coins? {
        if try loadBit() {
            return try loadCoins()
        }
        return nil
    }
}
