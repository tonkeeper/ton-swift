import Foundation

public struct DictionaryUIntValue: DictionaryValue {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? UInt64 else {
            throw TonError.custom("Wrong src type. Expected uint32")
        }
        
        try builder.storeUint(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.loadUint(bits: bits)
    }
}
