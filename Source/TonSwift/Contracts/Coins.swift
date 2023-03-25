import Foundation
import BigInt

public struct Coins {
    var amount: BigUInt
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

extension Coins: Writable {
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: self.amount, bits: 4)
    }
}

extension Coins: Readable {
    public static func readFrom(slice: Slice) throws -> Coins {
        return Coins(amount: try slice.bits.loadVarUintBig(bits: 4))
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
        if try bits.loadBit() {
            return try loadCoins()
        }
        return nil
    }
}
