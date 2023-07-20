import Foundation
import BigInt

/// 128-bit integer representing base TON currency: toncoins (aka `grams` in block.tlb).
public struct Coins: RawRepresentable, CellCodable {
    var amount: BigUInt
    
    init(_ a: some BinaryInteger) {
        // we use signed integer here because of `0` literal is a signed Int.
        amount = BigUInt(a)
    }

    // MARK: RawRepresentable

    public typealias RawValue = BigUInt

    public init?(rawValue: BigUInt) {
        amount = rawValue
    }

    public var rawValue: BigUInt {
        amount
    }

    // MARK: CellCodable

    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: amount, limit: 16)
    }

    public static func loadFrom(slice: Slice) throws -> Coins {
        Coins(try slice.loadVarUintBig(limit: 16))
    }
}
