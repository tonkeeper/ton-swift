import Foundation
import BigInt

public struct DictionaryKeyBuffer: DictionaryKeyCoder {
    public let bytes: Int
    
    public var bits: Int { return bytes*8 }
    
    public init(bytes: Int) {
        // We store bytes to preserve the alignment information
        self.bytes = bytes
    }

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? Data else {
            throw TonError.custom("Key is not a buffer")
        }

        return BigInt(
            try Cell(data: src)
                .beginParse()
                .bits.loadUintBig(bits: bytes * 8)
        )
    }

    public func parse(src: BigInt) throws -> any DictionaryKeyTypes {
        return try Builder()
            .storeUint(src, bits: bytes * 8)
            .endCell()
            .beginParse()
            .bits.loadBytes(bits)
    }
}
