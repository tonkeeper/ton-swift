import Foundation
import BigInt

public struct DictionaryBigVarUIntValue: DictionaryValue {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? BigUInt else {
            throw TonError.custom("Wrong src type. Expected biguint")
        }
        
        try builder.storeUint(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadVarUintBig(bits: bits)
    }
}
