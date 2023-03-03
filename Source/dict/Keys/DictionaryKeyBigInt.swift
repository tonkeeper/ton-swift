import Foundation
import BigInt

public struct DictionaryKeyBigInt: DictionaryKey {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? BigInt else {
            throw TonError.custom("Key is not a bigint")
        }
        
        return BigInt(
            try Builder()
                .storeInt(src, bits: bits)
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
            .loadIntBig(bits: bits)
    }
}
