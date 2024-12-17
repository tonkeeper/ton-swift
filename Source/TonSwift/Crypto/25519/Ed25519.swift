import Foundation
import CryptoKit

public enum Ed25519 {
    
    public enum Error: Swift.Error {
        case sharedSecretError(Swift.Error)
        case derivePathError(String)
    }
    
    static let ED25519_CURVE = "ed25519 seed"
    public static let HARDENED_OFFSET: UInt32 = 0x80000000
    
    public struct Keys {
        var key: Data
        var chainCode: Data
    }
    
    public static func getSharedSecret(privateKey: PrivateKey, publicKey: PublicKey) throws -> Data {
        do {
            let xPrivateKey = try privateKey.toX25519
            let xPublicKey = try publicKey.toX25519
            return try X25519.getSharedSecret(privateKey: xPrivateKey, publicKey: xPublicKey)
        } catch {
            throw Error.sharedSecretError(error)
            
        }
    }
    
    public static func getMasterKeyFromSeed(seed: String) throws -> Keys {
        guard let seedData = Data(hexString: seed) else {
            throw Error.derivePathError("Invalid seed hex string")
        }
        
        let hmac = HMAC<SHA512>.authenticationCode(for: seedData, using: SymmetricKey(data: ED25519_CURVE.data(using: .utf8)!))
        let I = Data(hmac)
        let IL = I.prefix(32)
        let IR = I.suffix(from: 32)
        
        return Keys(key: IL, chainCode: IR)
    }
    
    public static func CKDPriv(keys: Keys, index: UInt32) -> Keys {
        var indexData = Data(count: 4)
        indexData.withUnsafeMutableBytes { $0.bindMemory(to: UInt8.self).baseAddress?.withMemoryRebound(to: UInt32.self, capacity: 1) {
            $0.pointee = index.bigEndian
        }}
        
        let data = Data([0]) + keys.key + indexData
        let hmacValue = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: keys.chainCode))
        let I = Data(hmacValue)
        let IL = I.prefix(32)
        let IR = I.suffix(from: 32)
        
        return Keys(key: IL, chainCode: IR)
    }
    
    public static func isValidPath(path: String) -> Bool {
        let pathRegex = #"^m(\/[0-9]+')+$"#
        let regex = try? NSRegularExpression(pattern: pathRegex)
        
        let range = NSRange(location: 0, length: path.utf16.count)
        guard regex?.firstMatch(in: path, options: [], range: range) != nil else {
            return false
        }
        
        return !path.split(separator: "/").dropFirst().map { $0.replacingOccurrences(of: "'", with: "") }.contains { Int($0) == nil }
    }
    
    public static func derivePath(path: String, seed: String, offset: UInt32 = HARDENED_OFFSET) throws -> Keys {
        guard isValidPath(path: path) else {
            throw Error.derivePathError("Invalid derivation path")
        }
        
        var keys = try getMasterKeyFromSeed(seed: seed)
        
        let segments = path
            .split(separator: "/")
            .dropFirst()
            .map { $0.replacingOccurrences(of: "'", with: "") }
            .compactMap { UInt32($0) }
        
        for segment in segments {
            keys = CKDPriv(keys: keys, index: segment + offset)
        }
        
        return keys
    }
}

extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        var index = hexString.startIndex
        for _ in 0..<length {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
