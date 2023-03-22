import Foundation

public struct DictionaryValueCell: DictionaryValueCoder {
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Cell else {
            throw TonError.custom("Wrong src type. Expected cell")
        }
        
        try builder.storeRef(cell: src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.loadRef()
    }
}
