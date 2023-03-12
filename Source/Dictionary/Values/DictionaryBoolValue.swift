import Foundation

public struct DictionaryBoolValue: DictionaryValue {
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Bool else {
            throw TonError.custom("Wrong src type. Expected bool")
        }
        
        try builder.storeBit(src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.loadBit()
    }
}
