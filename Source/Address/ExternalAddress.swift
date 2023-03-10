import Foundation
import BigInt

public struct ExternalAddress {
    private(set) var value: BigInt
    private(set) var bits: Int

    public init(value: BigInt, bits: Int) {
        self.value = value
        self.bits = bits
    }

    public func toString() -> String {
        return "External<\(bits):\(value)>"
    }

    public static func isAddress(_ src: Any) -> Bool {
        return src is ExternalAddress
    }
}
