import Foundation
import BigInt

public struct Coins {
    var amount: BigInt
}

extension Coins: RawRepresentable {
    public typealias RawValue = BigInt;

    public init?(rawValue: BigInt) {
        self.amount = rawValue
    }

    public var rawValue: BigInt {
        return self.amount
    }
}
