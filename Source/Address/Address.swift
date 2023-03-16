import Foundation

/// By default, addresses are bounceable for safety of TON transfers.
public let BounceableDefault = true;

public struct Address: Hashable {
    public let workchain: Int8
    public let hash: Data
    
    /// Initializes address from raw components.
    public init(workchain: Int8, hash: Data) {
        self.workchain = workchain
        self.hash = hash
    }
    
    /// Generates a test address
    public static func mock(workchain: Int8, seed: String) -> Self {
        return Address(workchain: workchain, hash: Data(seed.utf8).sha256())
    }
    
    public static func isAddress(_ src: Any) -> Bool {
        return src is Address
    }
    
    public static func isFriendly(source: String) -> Bool {
        return source.firstIndex(of: ":") == nil
    }
    
    public static func normalize(source: String) throws -> String {
        return (try Address.parse(source)).toString()
    }
    
    public static func normalize(source: Address) throws -> String {
        return source.toString()
    }
    
    public static func parse(_ source: String) throws -> Address {
        if isFriendly(source: source) {
            return try FriendlyAddress(string: source).address
        } else {
            return try parse(raw: source)
        }
    }
    
    /// Initializes address from the raw format `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public static func parse(raw: String) throws -> Address {
        let parts = raw.split(separator: ":");
        guard parts.count == 2 else {
            throw TonError.custom("Raw address is malformed: should be in the form `<workchain number>:<hex>`")
        }
        guard let wc = Int8(parts[0], radix: 10) else {
            throw TonError.custom("Raw address is malformed: workchain must be a decimal integer")
        }
        guard let hash = Data(hex: String(parts[1])) else {
            throw TonError.custom("Raw address is malformed: hash part should be correctly hex-encoded")
        }
        return Address(workchain: wc, hash: hash)
    }

    
    public func toRawString() -> String {
        return "\(workchain):\(hash.hexString())"
    }
    
    public func toRaw() -> Data {
        var addressWithChecksum = Data(count: 36)
        addressWithChecksum.replaceSubrange(0..<hash.count, with: hash)
        
        var workchain: UInt8
        if self.workchain == -1 {
            workchain = UInt8.max
        } else {
            workchain = UInt8(self.workchain)
        }
        
        addressWithChecksum.replaceSubrange(32..<36, with: [workchain, workchain, workchain, workchain])
        
        return addressWithChecksum
    }
    
    public func toStringBuffer(testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> Data {
        var tag = bounceable ? bounceableTag : nonBounceableTag
        if testOnly {
            tag |= testFlag
        }
        
        var workchain: UInt8
        if self.workchain == -1 {
            workchain = UInt8.max
        } else {
            workchain = UInt8(self.workchain)
        }
        
        var addr = Data(count: 34)
        addr[0] = tag
        addr[1] = workchain
        addr[2...] = hash
        var addressWithChecksum = Data(count: 36)
        addressWithChecksum[0...] = addr
        addressWithChecksum[34...] = addr.crc16()
        
        return addressWithChecksum
    }
    
    public func toString(urlSafe: Bool = true, testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> String {
        let buffer = toStringBuffer(testOnly: testOnly, bounceable: bounceable)
        if urlSafe {
            return buffer.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        } else {
            return buffer.base64EncodedString()
        }
    }
}

// MARK: - Equatable
extension Address: Equatable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.workchain != rhs.workchain {
            return false
        }
        
        return lhs.hash == rhs.hash
    }
}

/// ```
/// anycast_info$_ depth:(#<= 30) { depth >= 1 }
///                rewrite_pfx:(bits depth)        = Anycast;
/// addr_std$10 anycast:(Maybe Anycast)
///             workchain_id:int8
///             address:bits256                    = MsgAddressInt;
/// addr_var$11 anycast:(Maybe Anycast)
///             addr_len:(## 9)
///             workchain_id:int32
///             address:(bits addr_len)            = MsgAddressInt;
/// ```
extension Address: Writable, Readable {
    public func writeTo(builder b: Builder) throws {
        try b.storeUint(UInt64(2), bits: 2) // $10
        try b.storeUint(UInt64(0), bits: 1)
        try b.storeInt(Int(self.workchain), bits: 8)
        try b.storeBuffer(self.hash)
    }
    
    public static func readFrom(slice: Slice) throws -> Address {
        return try slice.tryLoad { s in
            let type = try s.bits.loadUint(bits: 2)
            if type != 2 {
                throw TonError.custom("Invalid address: expecting internal address `addr_std$10`")
            }
            
            // No Anycast supported
            let anycastPrefix = try s.bits.loadUint(bits: 1);
            if anycastPrefix != 0 {
                throw TonError.custom("Invalid address: anycast not supported")
            }

            // Read address
            let wc = Int8(try s.bits.loadInt(bits: 8))
            let hash = try s.bits.loadBytes(32)

            return Address(workchain: wc, hash: hash)
        }
    }
}
