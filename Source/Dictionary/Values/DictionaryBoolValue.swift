import Foundation

public struct DictionaryBoolValue: DictionaryValueCoder {
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Bool else {
            throw TonError.custom("Wrong src type. Expected bool")
        }
        
        try builder.bits.write(bit: src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadBit()
    }
}
