import Foundation
import BigInt

public struct DictionaryKeyUInt: DictionaryKey {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? UInt32 else {
            throw TonError.custom("Key is not a uint")
        }

        return BigInt(
            try Builder()
                .storeUint(UInt64(src), bits: bits)
                .endCell()
                .beginParse()
                .loadUintBig(bits: bits)
        )
    }

    public func parse(src: BigInt) throws -> any DictionaryKeyTypes {
        return try Builder()
            .storeUint(src, bits: bits)
            .endCell()
            .beginParse()
            .loadUint(bits: bits)
    }
}
