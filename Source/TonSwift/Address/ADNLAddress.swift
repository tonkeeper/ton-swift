import Foundation

struct ADNLAddress: Equatable {
    static func parseFriendly(_ src: String) throws -> ADNLAddress {
        if src.count != 55 {
            throw TonError.custom("Invalid address")
        }

        let decoded = try "f\(src)".fromBase32()
        if decoded[0] != 0x2d {
            throw TonError.custom("Invalid address")
        }

        let gotHash = decoded[33...].bytes
        let hash = decoded[0..<33].bytes.crc16()
        if !hash.bytes.elementsEqual(gotHash) {
            throw TonError.custom("Invalid address")
        }

        return try ADNLAddress(address: decoded[1..<33].bytes)
    }

    static func parseRaw(_ src: String) throws -> ADNLAddress {
        try ADNLAddress(address: Data(base64Encoded: src)!)
    }

    let address: Data
    
    init(address: Data) throws {
        if address.count != 32 {
            throw TonError.custom("Invalid address")
        }
        
        self.address = address
    }
    
    func toRaw() -> String {
        address.map { String(format: "%02X", $0) }.joined().uppercased()
    }

    func toString() -> String {
        var data = Data([0x2D]) + address
        let hash = data.crc16()
        data = data + hash
        
        return String(data.toBase32().dropFirst())
    }

    // MARK: - Equatable

    static func == (lhs: ADNLAddress, rhs: ADNLAddress) -> Bool {
        lhs.address == rhs.address
    }
}
