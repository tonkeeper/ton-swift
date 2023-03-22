import Foundation
import BigInt

public struct DictionaryValueBigInt: DictionaryValueCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? BigInt else {
            throw TonError.custom("Wrong src type. Expected bigint")
        }
        
        try builder.storeInt(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadIntBig(bits: bits)
    }
}
