import Foundation
import BigInt

/// Every type that can be used as a dictionary value has an accompanying coder object configured to read that type.
public protocol DictionaryValueCoder {
    func serialize(src: any DictionaryKeyTypes, builder: Builder) throws
    func parse(src: Slice) throws -> any DictionaryKeyTypes
}

public struct DictionaryValueAddress: DictionaryValueCoder {
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

public struct DictionaryValueBigUInt: DictionaryValueCoder {
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
        return try src.bits.loadUintBig(bits: bits)
    }
}

public struct DictionaryValueBigVarUInt: DictionaryValueCoder {
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

public struct DictionaryValueBool: DictionaryValueCoder {
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

public struct DictionaryValueBuffer: DictionaryValueCoder {
    public let bytes: Int
    
    public init(bytes: Int) {
        self.bytes = bytes
    }
    
    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Data else {
            throw TonError.custom("Wrong src type. Expected buffer")
        }
        
        guard src.count == bytes else {
            throw TonError.custom("Invalid buffer size")
        }
        
        try builder.bits.write(data: src)
    }
    
    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadBytes(bytes)
    }
}

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

public struct DictionaryValueUInt: DictionaryValueCoder {
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
        return try src.bits.loadUint(bits: bits)
    }
}
