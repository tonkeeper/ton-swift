import Foundation

public struct DictionaryValueInt: DictionaryValueCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Int else {
            throw TonError.custom("Wrong src type. Expected int")
        }
        
        try builder.storeInt(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadInt(bits: bits)
    }
}
