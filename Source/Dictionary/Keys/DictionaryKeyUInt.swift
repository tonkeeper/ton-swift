import Foundation
import BigInt

public struct DictionaryKeyUInt: DictionaryKey {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? UInt64 else {
            throw TonError.custom("Key is not a uint")
        }

        return BigInt(
            try Builder()
                .storeUint(src, bits: bits)
                .endCell()
                .beginParse()
                .bits.loadUintBig(bits: bits)
        )
    }

    public func parse(src: BigInt) throws -> any DictionaryKeyTypes {
        return try Builder()
            .storeUint(src, bits: bits)
            .endCell()
            .beginParse()
            .bits.loadUint(bits: bits)
    }
}
