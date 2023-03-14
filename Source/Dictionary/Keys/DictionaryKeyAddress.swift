import Foundation
import BigInt

public struct DictionaryKeyAddress: DictionaryKey {
    public let bits: Int = 267

    public func serialize(src: any DictionaryKeyTypes) throws -> BigInt {
        guard let src = src as? Address else {
            throw TonError.custom("Key is not an address")
        }
        
        return BigInt(
            try Builder()
                .storeAddress(address: src)
                .endCell().beginParse()
                .bits.preloadUintBig(bits: bits)
        )
    }

    public func parse(src: BigInt) throws -> any DictionaryKeyTypes {
        return try Builder()
            .storeUint(src, bits: bits)
            .endCell()
            .beginParse()
            .loadAddress()
    }
}
