import Foundation

public struct DictionaryAddressValue: DictionaryValueCoder {
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Address else {
            throw TonError.custom("Wrong src type. Expected Address")
        }
        
        try builder.store(src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        let a: Address = try src.loadType()
        return a
    }
}
