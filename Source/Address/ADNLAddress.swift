import Foundation

struct ADNLAddress {
    static func parseFriendly(_ src: String) throws -> ADNLAddress {
        if src.count != 55 {
            throw TonError.custom("Invalid address")
        }

        let decoded = try base32Decode(input: "f\(src)")
        if decoded[0] != 0x2d {
            throw TonError.custom("Invalid address")
        }

        let gotHash = decoded[33...].bytes
        let hash = crc16(data: decoded[0..<33].bytes)
        if !hash.bytes.elementsEqual(gotHash) {
            throw TonError.custom("Invalid address")
        }

        return try ADNLAddress(address: decoded[1..<33].bytes)
    }

    static func parseRaw(_ src: String) throws -> ADNLAddress {
        let data = Data(base64Encoded: src)
        
        return try ADNLAddress(address: data!)
    }

    let address: Data
    
    init(address: Data) throws {
        if address.count != 32 {
            throw TonError.custom("Invalid address")
        }
        
        self.address = address
    }
    
    func toRaw() -> String {
        return address.map { String(format: "%02X", $0) }.joined().uppercased()
    }

    func toString() -> String {
        var data = Data([0x2D]) + self.address
        let hash = crc16(data: data)
        data = data + hash
        
        return String(base32Encode(buffer: data).dropFirst())
    }

}

// MARK: - Equatable
extension ADNLAddress: Equatable {
    static func == (lhs: ADNLAddress, rhs: ADNLAddress) -> Bool {
        return lhs.address == rhs.address
    }
}
