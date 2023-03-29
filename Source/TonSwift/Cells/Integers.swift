import Foundation
import BigInt

/// Represents unary integer encoding: `0` for 0, `10` for 1, `110` for 2, `1{n}0` for n.
public struct Unary: Readable, Writable {
    public let value: Int
    
    init(_ v: Int) {
        value = v
    }
    
    public func writeTo(builder: Builder) throws {
        for _ in 0..<value {
            try builder.bits.write(bit: true)
        }
        try builder.bits.write(bit: false)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        var v: Int = 0
        while try slice.loadBit() {
            v += 1
        }
        return Unary(v)
    }
}

extension Bool: Codeable, StaticSize {
    public static var bitWidth: Int = 1
        
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(bit: self)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return try slice.loadBit()
    }
}

/// 256-bit unsigned integer
public struct UInt256: Hashable, Codeable, StaticSize {
    public var value: BigUInt
    
    public static var bitWidth: Int = 256
    
    init(biguint: BigUInt) {
        value = biguint
    }
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: value, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(biguint: try slice.loadUintBig(bits: Self.bitWidth))
    }
}

// Unsigned short integers

extension UInt8: Codeable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt16: Codeable, StaticSize {
    public static var bitWidth: Int = 16
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt32: Codeable, StaticSize {
    public static var bitWidth: Int = 32
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

extension UInt64: Codeable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadUint(bits: Self.bitWidth))
    }
}

// Signed short integers

extension Int8: Codeable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(int: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int16: Codeable, StaticSize {
    public static var bitWidth: Int = 16
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(int: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int32: Codeable, StaticSize {
    public static var bitWidth: Int = 32
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(int: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}

extension Int64: Codeable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(int: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.loadInt(bits: Self.bitWidth))
    }
}



//
// Dynamically-sized integers
//

/// Up-to-31-byte (248-bit) unsigned integer (5-bit length prefix)
public struct VarUInt248: Hashable, Codeable {
    public var value: BigUInt
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: value, bits: 5)
    }
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.loadVarUintBig(bits: 5))
    }
}

/// Up-to-15-byte (120-bit) unsigned integer (4-bit length prefix)
public struct VarUInt120: Hashable, Codeable {
    public var value: BigUInt
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: value, bits: 4)
    }
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.loadVarUintBig(bits: 4))
    }
}

public struct IntCoder: TypeCoder {
    public typealias T = BigInt
    
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: T, builder: Builder) throws {
        try builder.storeInt(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> T {
        return try src.loadIntBig(bits: bits)
    }
}

public struct UIntCoder: TypeCoder {
    public typealias T = BigUInt
    
    public let bits: Int
     
    public init(bits: Int) {
        self.bits = bits
    }
    
    public func serialize(src: T, builder: Builder) throws {
        try builder.storeUint(src, bits: bits)
    }
    
    public func parse(src: Slice) throws -> T {
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
    
    public func serialize(src: T, builder: Builder) throws {
        try builder.storeVarUint(value: src, bits: prefixbits)
    }
    
    public func parse(src: Slice) throws -> T {
        return try src.loadVarUintBig(bits: prefixbits)
    }
}
