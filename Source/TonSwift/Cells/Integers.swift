import Foundation
import BigInt

/// Represents unary integer encoding: `0` for 0, `10` for 1, `110` for 2, `1{n}0` for n.
public struct Unary: CellCodable {
    public let value: Int
    
    init(_ v: Int) {
        value = v
    }
    
    public func storeTo(builder: Builder) throws {
        for _ in 0..<value {
            try builder.store(bit: true)
        }
        try builder.store(bit: false)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        var v: Int = 0
        while try slice.loadBit() {
            v += 1
        }
        return Unary(v)
    }
}

extension Bool: CellCodable, StaticSize {
    public static var bitWidth: Int = 1
        
    public func storeTo(builder: Builder) throws {
        try builder.store(bit: self)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return try slice.loadBit()
    }
}

/// 256-bit unsigned integer
public struct UInt256: Hashable, CellCodable, StaticSize {
    public var value: BigUInt
    
    public static var bitWidth: Int = 256
    
    init(biguint: BigUInt) {
        value = biguint
    }
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: value, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(biguint: try slice.loadUintBig(bits: Self.bitWidth))
    }
}

// Unsigned short integers

extension UInt8: CellCodable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt16: CellCodable, StaticSize {
    public static var bitWidth: Int = 16
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt32: CellCodable, StaticSize {
    public static var bitWidth: Int = 32
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt64: CellCodable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func storeTo(builder: Builder) throws {
        try builder.store(uint: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

// Signed short integers

extension Int8: CellCodable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func storeTo(builder: Builder) throws {
        try builder.store(int: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int16: CellCodable, StaticSize {
    public static var bitWidth: Int = 16
    
    public func storeTo(builder: Builder) throws {
        try builder.store(int: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int32: CellCodable, StaticSize {
    public static var bitWidth: Int = 32
    
    public func storeTo(builder: Builder) throws {
        try builder.store(int: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int64: CellCodable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func storeTo(builder: Builder) throws {
        try builder.store(int: self, bits: Self.bitWidth)
    }
    
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}



//
// Dynamically-sized integers
//

/// Up-to-31-byte (248-bit) unsigned integer (5-bit length prefix)
public struct VarUInt248: Hashable, CellCodable {
    public var value: BigUInt
    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: value, prefixSize: 5)
    }
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.loadVarUintBig(bits: 5))
    }
}

/// Up-to-15-byte (120-bit) unsigned integer (4-bit length prefix)
public struct VarUInt120: Hashable, CellCodable {
    public var value: BigUInt
    public func storeTo(builder: Builder) throws {
        try builder.store(varuint: value, prefixSize: 4)
    }
    public static func loadFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.loadVarUintBig(bits: 4))
    }
}

public struct IntCoder: TypeCoder {
    public typealias T = BigInt
    
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(int: src, bits: bits)
    }
    
    public func loadValue(from src: Slice) throws -> T {
        return try src.loadIntBig(bits: bits)
    }
}

public struct UIntCoder: TypeCoder {
    public typealias T = BigUInt
    
    public let bits: Int
     
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(uint: src, bits: bits)
    }
    
    public func loadValue(from src: Slice) throws -> T {
        return try src.loadUintBig(bits: bits)
    }
}

/// Encodes variable-length integers using `p`-long length prefix for size in _bytes_.
/// Therefore, `VarUIntCoder(5)` can fit `2^5` = `32` byte-long integers, therefore representing 256-bit integers.
/// TL-B:
/// ```
/// var_uint$_ {n:#} len:(#< n) value:(uint (len * 8)) = VarUInteger n;
/// var_int$_  {n:#} len:(#< n) value:(int (len * 8))  = VarInteger n;
/// ```
/// TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify bounds when reading the result.
public struct VarUIntCoder: TypeCoder {
    public typealias T = BigUInt
    
    public let prefixbits: Int
    
    public init(prefixbits: Int) {
        self.prefixbits = prefixbits
    }
    
    public func storeValue(_ src: T, to builder: Builder) throws {
        try builder.store(varuint: src, prefixSize: prefixbits)
    }
    
    public func loadValue(from src: Slice) throws -> T {
        return try src.loadVarUintBig(bits: prefixbits)
    }
}
