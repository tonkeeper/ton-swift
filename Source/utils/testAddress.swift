import Foundation
import BigInt

public func testAddress(workchain: Int8, seed: String) -> Address {
    var hash = Data(count: 32)
    for i in 0..<hash.count {
        hash[i] = UInt8.random(in: 0...255)
    }
    
    return Address(workChain: workchain, hash: hash)
}

public func testExternalAddress(workchain: Int8, seed: String) throws -> ExternalAddress {
    var hash = Data(count: 32)
    for i in 0..<hash.count {
        hash[i] = UInt8.random(in: 0...255)
    }
    
    let value = BigInt(hash.hexString(), radix: 16)!
    
    return ExternalAddress(value: value, bits: try bitsForNumber(src: value, mode: "uint"))
}
