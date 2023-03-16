import Foundation

/// By default, addresses are bounceable for safety of TON transfers.
public let BounceableDefault = true;

let bounceableTag: UInt8 = 0x11
let nonBounceableTag: UInt8 = 0x51
let testFlag: UInt8 = 0x80


struct FriendlyAddress: Codable {
    let isTestOnly: Bool
    let isBounceable: Bool
    let workchain: Int8
    let hashPart: Data
    
    var address: Address {
        return Address(workchain: self.workchain, hash: self.hashPart)
    }
    
    init(string: String) throws {
        // Convert from url-friendly to true base64
        let string = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: string) else {
            throw TonError.custom("Address is not correctly encoded in Base64")
        }
        try self.init(data: data)
    }
    
    init(data: Data) throws {
        // 1byte tag + 1byte workchain + 32 bytes hash + 2 byte crc
        if data.count != 36 {
            throw TonError.custom("Unknown address type: byte length is not equal to 36")
        }
        
        let addr = data.subdata(in: 0..<34)
        let crc = data.subdata(in: 34..<36)
        let calcedCrc = addr.crc16()
        
        if calcedCrc[0] != crc[0] || calcedCrc[1] != crc[1] {
            throw TonError.custom("Invalid checksum: \(data)")
        }

        var tag = addr[0]
        if tag & testFlag != 0 {
            self.isTestOnly = true
            tag = tag ^ testFlag
        } else {
            self.isTestOnly = false
        }

        if tag != bounceableTag && tag != nonBounceableTag {
            throw TonError.custom("Unknown address tag")
        }

        self.isBounceable = (tag == bounceableTag)

        if addr[1] == 0xff {
            self.workchain = -1
        } else {
            self.workchain = Int8(addr[1])
        }
        self.hashPart = addr.subdata(in: 2..<34)
    }
}

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
