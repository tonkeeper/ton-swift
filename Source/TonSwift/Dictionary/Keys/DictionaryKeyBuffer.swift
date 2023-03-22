import Foundation
import BigInt

public struct DictionaryKeyBuffer: DictionaryKey {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits * 8
    }

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? Data else {
            throw TonError.custom("Key is not a buffer")
        }

        return BigInt(
            try Cell(data: src)
                .beginParse()
                .bits.loadUintBig(bits: bits * 8)
        )
    }

    public func parse(src: BigInt) throws -> any DictionaryKeyTypes {
        return try Builder()
            .storeUint(src, bits: bits * 8)
            .endCell()
            .beginParse()
            .bits.loadBytes(bits)
    }
}
