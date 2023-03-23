import Foundation
import BigInt

public struct DictionaryKeyAddress: DictionaryKeyCoder {
    public let bits: Int = 267

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Address else {
            throw TonError.custom("Key is not an address")
        }
        
        try builder.store(src)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        let a:Address = try src.loadType()
        return a
    }
}

public struct DictionaryKeyBigInt: DictionaryKeyCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? BigInt else {
            throw TonError.custom("Key is not a bigint")
        }
        
        try builder.storeInt(src, bits: bits)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadIntBig(bits: bits)
    }
}

public struct DictionaryKeyBigUInt: DictionaryKeyCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? BigUInt else {
            throw TonError.custom("Key is not a biguint")
        }
        try builder.storeInt(src, bits: bits)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadIntBig(bits: bits)
    }
}


public struct DictionaryKeyBuffer: DictionaryKeyCoder {
    public let bytes: Int
    
    public var bits: Int { return bytes*8 }
    
    public init(bytes: Int) {
        // We store bytes to preserve the alignment information
        self.bytes = bytes
    }

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Data else {
            throw TonError.custom("Key is not a buffer")
        }
        try builder.bits.write(data: src)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadBytes(bits)
    }
}

public struct DictionaryKeyInt: DictionaryKeyCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? Int else {
            throw TonError.custom("Key is not a int")
        }
        try builder.storeInt(src, bits: bits)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadInt(bits: bits)
    }
}


public struct DictionaryKeyUInt: DictionaryKeyCoder {
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }

    public func serialize(src: any DictionaryKeyTypes, builder: Builder) throws {
        guard let src = src as? UInt64 else {
            throw TonError.custom("Key is not a uint")
        }

        try builder.storeUint(src, bits: bits)
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadUint(bits: bits)
    }
}
