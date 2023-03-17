import Foundation

public struct DictionaryBufferValue: DictionaryValue {
    public let size: Int
    
    public init(size: Int) {
        self.size = size
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Data else {
            throw TonError.custom("Wrong src type. Expected buffer")
        }
        
        guard src.count == size else {
            throw TonError.custom("Invalid buffer size")
        }
        
        try builder.bits.writeData(src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadBytes(size)
    }
}
