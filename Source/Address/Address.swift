import Foundation

struct FriendlyAddress: Codable {
    let isTestOnly: Bool
    let isBounceable: Bool
    let workchain: Int8
    let hashPart: Data
}

let bounceableTag: UInt8 = 0x11
let nonBounceableTag: UInt8 = 0x51
let testFlag: UInt8 = 0x80

func parseFriendlyAddress(src: String) throws -> FriendlyAddress {
    guard let data = Data(base64Encoded: src) else {
        throw TonError.custom("Invalid src")
    }
    
    return try parseFriendlyAddress(src: data)
}

func parseFriendlyAddress(src: Data) throws -> FriendlyAddress {
    // 1byte tag + 1byte workchain + 32 bytes hash + 2 byte crc
    if src.count != 36 {
        throw TonError.custom("Unknown address type: byte length is not equal to 36")
    }
    
    let addr = src.subdata(in: 0..<34)
    let crc = src.subdata(in: 34..<36)
    let calcedCrc = addr.crc16()
    
    if calcedCrc[0] != crc[0] || calcedCrc[1] != crc[1] {
        throw TonError.custom("Invalid checksum: \(src)")
    }

    var tag = addr[0]
    var isTestOnly = false
    var isBounceable = false
    if tag & testFlag != 0 {
        isTestOnly = true
        tag = tag ^ testFlag
    }

    if tag != bounceableTag && tag != nonBounceableTag {
        throw TonError.custom("Unknown address tag")
    }

    isBounceable = tag == bounceableTag

    var workchain: Int8
    if addr[1] == 0xff {
        workchain = -1
    } else {
        workchain = Int8(addr[1])
    }

    let hashPart = addr.subdata(in: 2..<34)

    return FriendlyAddress(isTestOnly: isTestOnly, isBounceable: isBounceable, workchain: workchain, hashPart: hashPart)
}

public struct Address: Hashable {
    private let _workchain: Int8
    public let hash: Data
    
    public init(workchain: Int8, hash: Data) {
        self._workchain = workchain
        self.hash = hash
    }
    
    /// Generates a test address
    public static func mock(workchain: Int8, seed: String) -> Self {
        return Address(workchain: workchain, hash: Data(seed.utf8).sha256())
    }
    
    public var workchain: UInt8 {
        if _workchain == -1 {
            return UInt8.max
        } else {
            return UInt8(_workchain)
        }
    }
    
    public static func isAddress(_ src: Any) -> Bool {
        return src is Address
    }
    
    public static func isFriendly(source: String) -> Bool {
        return source.firstIndex(of: ":") == nil
    }
    
    public static func normalize(source: String) throws -> String {
        return try Address.parse(source: source).toString()
    }
    
    public static func normalize(source: Address) throws -> String {
        return source.toString()
    }
    
    public static func parse(source: String) throws -> Address {
        if isFriendly(source: source) {
            return try parseFriendly(source: source).address
        } else {
            return parseRaw(source: source)
        }
    }
    
    public static func parseRaw(source: String) -> Address {
        let workchain = Int8(source.split(separator: ":")[0])!
        let hash = Data(hex: String(source.split(separator: ":")[1]))!
        
        return Address(workchain: workchain, hash: hash)
    }
    
    public static func parseFriendly(source: Data) throws -> (isBounceable: Bool, isTestOnly: Bool, address: Address) {
        let r = try parseFriendlyAddress(src: source)
        return (isBounceable: r.isBounceable, isTestOnly: r.isTestOnly, address: Address(workchain: r.workchain, hash: r.hashPart))
    }

    public static func parseFriendly(source: String) throws -> (isBounceable: Bool, isTestOnly: Bool, address: Address) {
        let addr = source.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") // Convert from url-friendly to true base64
        let r = try parseFriendlyAddress(src: addr)
        return (isBounceable: r.isBounceable, isTestOnly: r.isTestOnly, address: Address(workchain: r.workchain, hash: r.hashPart))
    }
    
    public func toRawString() -> String {
        return "\(workchain):\(hash.hexString())"
    }
    
    public func toRaw() -> Data {
        var addressWithChecksum = Data(count: 36)
        addressWithChecksum.replaceSubrange(0..<hash.count, with: hash)
        addressWithChecksum.replaceSubrange(32..<36, with: [UInt8(workchain), UInt8(workchain), UInt8(workchain), UInt8(workchain)])
        
        return addressWithChecksum
    }
    
    public func toStringBuffer(testOnly: Bool? = nil, bounceable: Bool? = nil) -> Data {
        let testOnly = testOnly ?? false
        let bounceable = bounceable ?? true
        var tag = bounceable ? bounceableTag : nonBounceableTag
        if testOnly {
            tag |= testFlag
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
    
    public func toString(urlSafe: Bool? = nil, testOnly: Bool? = nil, bounceable: Bool? = nil) -> String {
        let urlSafe = urlSafe ?? true
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
