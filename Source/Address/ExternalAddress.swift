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
    
    public static func mock(seed: String) throws -> Self {
        let value = BigInt(Data(seed.utf8).sha256().hexString(), radix: 16)!
        return ExternalAddress(value: value, bits: try value.bitsCount(mode: .uint))
    }
}
