import Foundation
import BigInt

public struct ExternalAddress {
    private(set) var value: BitString

    public init(value: BitString) {
        self.value = value
    }

    public func toString() throws -> String {
        return "External<\(value.length):\(try value.toString())>"
    }
    
    public static func mock(seed: String) throws -> Self {
        let value = BitString(data: Data(seed.utf8).sha256())
        return ExternalAddress(value: value)
    }
}
