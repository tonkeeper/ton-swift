import Foundation
import BigInt

/// External address TL-B definition:
/// ```
/// addr_extern$01 len:(## 9) external_address:(bits len) = MsgAddressExt;
/// ```
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

extension ExternalAddress: Readable, Writable {
    public func writeTo(builder: Builder) throws {
        try builder.storeUint(UInt64(1), bits: 2)
        try builder.storeUint(UInt64(self.value.length), bits: 9)
        try builder.storeBits(self.value)
    }
    
    public static func readFrom(slice: Slice) throws -> ExternalAddress {
        return try slice.tryLoad { s in
            let type = try s.bits.loadUint(bits: 2)
            if type != 1 {
                throw TonError.custom("Invalid ExternalAddress")
            }
            
            let bits = Int(try s.bits.loadUint(bits: 9))
            let data = try s.bits.loadBits(bits)
            
            return ExternalAddress(value: data)
        }
    }
}
