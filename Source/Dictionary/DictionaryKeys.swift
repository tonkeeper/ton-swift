import Foundation
import BigInt

public typealias DictionaryKeyTypes = Hashable

/// Every type that can be used as a dictionary key has an accompanying coder object configured to read that type.
public protocol DictionaryKeyCoder {
    var bits: Int { get }
    func serialize(src: any DictionaryKeyTypes) throws -> BitString
    func parse(src: Slice) throws -> any DictionaryKeyTypes
}

public struct DictionaryKeyAddress: DictionaryKeyCoder {
    public let bits: Int = 267

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? Address else {
            throw TonError.custom("Key is not an address")
        }
        
        return try Builder().store(src).endCell().bits
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

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? BigInt else {
            throw TonError.custom("Key is not a bigint")
        }
        
        return try Builder()
                .storeInt(src, bits: bits)
                .endCell()
                .bits
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

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? BigUInt else {
            throw TonError.custom("Key is not a biguint")
        }
        
        return try Builder()
                .storeInt(src, bits: bits)
                .endCell()
                .bits
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

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? Data else {
            throw TonError.custom("Key is not a buffer")
        }

        return BitString(data: src)
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

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? Int else {
            throw TonError.custom("Key is not a int")
        }
        return try Builder()
                .storeInt(src, bits: bits)
                .endCell()
                .bits
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

    public func serialize(src: any DictionaryKeyTypes) throws -> BitString {
        guard let src = src as? UInt64 else {
            throw TonError.custom("Key is not a uint")
        }

        return try Builder()
                .storeUint(src, bits: bits)
                .endCell()
                .bits
    }

    public func parse(src: Slice) throws -> any DictionaryKeyTypes {
        return try src.bits.loadUint(bits: bits)
    }
}
