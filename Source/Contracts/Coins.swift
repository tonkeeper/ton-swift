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
