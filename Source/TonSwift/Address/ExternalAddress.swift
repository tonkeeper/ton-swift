import Foundation

/// External address TL-B definition:
/// ```
/// addr_extern$01 len:(## 9) external_address:(bits len) = MsgAddressExt;
/// ```
public struct ExternalAddress: CellCodable {
    private(set) var value: Bitstring

    public init(value: Bitstring) {
        self.value = value
    }

    public func toString() -> String {
        "External<\(value.length):\(value.toString())>"
    }
    
    public static func mock(seed: String) throws -> Self {
        ExternalAddress(value: Bitstring(data: Data(seed.utf8).sha256()))
    }

    public func storeTo(builder: Builder) throws {
        try builder
            .store(uint: 1, bits: 2)
            .store(uint: value.length, bits: 9)
            .store(bits: value)
    }
    
    public static func loadFrom(slice: Slice) throws -> ExternalAddress {
        try slice.tryLoad { s in
            let type = try s.loadUint(bits: 2)
            if type != 1 {
                throw TonError.custom("Invalid ExternalAddress")
            }
            
            let bits = Int(try s.loadUint(bits: 9))
            let data = try s.loadBits(bits)
            
            return ExternalAddress(value: data)
        }
    }
}
