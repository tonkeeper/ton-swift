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
        while try slice.bits.loadBit() {
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
        return try slice.bits.loadBit()
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
        return Self(biguint: try slice.bits.loadUintBig(bits: Self.bitWidth))
    }
}

extension UInt8: Codeable, StaticSize {
    public static var bitWidth: Int = 8
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.bits.loadUint(bits: Self.bitWidth))
    }
}

extension UInt16: Codeable, StaticSize {
    public static var bitWidth: Int = 16
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.bits.loadUint(bits: Self.bitWidth))
    }
}

extension UInt32: Codeable, StaticSize {
    public static var bitWidth: Int = 32
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.bits.loadUint(bits: Self.bitWidth))
    }
}

extension UInt64: Codeable, StaticSize {
    public static var bitWidth: Int = 64
    
    public func writeTo(builder: Builder) throws {
        try builder.bits.write(uint: self, bits: Self.bitWidth)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(try slice.bits.loadUint(bits: Self.bitWidth))
    }
}


//
// Dynamically-sized integers
//

/// Up-to-31-byte (248-bit) unsigned integer
public struct VarUInt248: Hashable, Codeable {
    public var value: BigUInt
    
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: value, bits: 5)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.bits.loadVarUintBig(bits: 5))
    }
}

/// Up-to-15-byte (120-bit) unsigned integer
public struct VarUInt120: Hashable, Codeable {
    public var value: BigUInt
    
    public func writeTo(builder: Builder) throws {
        try builder.storeVarUint(value: value, bits: 4)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return Self(value: try slice.bits.loadVarUintBig(bits: 4))
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
        return try src.bits.loadIntBig(bits: bits)
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
        return try src.bits.loadUintBig(bits: bits)
    }
}

/// Encodes variable-length integers using `p`-long length prefix for size in _bytes_.
/// Therefore, `VarUIntCoder(5)` can fit `2^5` = `32` byte-long integers, therefore representing 256-bit integers.
/// TL-B:
/// ```
/// var_uint$_ {n:#} len:(#< n) value:(uint (len * 8)) = VarUInteger n;
/// var_int$_  {n:#} len:(#< n) value:(int (len * 8))  = VarInteger n;
/// ```
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
        return try src.bits.loadVarUintBig(bits: prefixbits)
    }
}




//extension UInt256: UnsignedInteger {
//
//    public typealias Words = BigUInt.Words
//    public typealias IntegerLiteralType = BigUInt.IntegerLiteralType
//
//    public var bitWidth: Int {
//        return self.value.bitWidth
//    }
//
//    public var trailingZeroBitCount: Int {
//        return self.value.trailingZeroBitCount
//    }
//
//    public var words: BigUInt.Words {
//        return value.words
//    }
//
//    public init<T>(_ source: T) where T : BinaryInteger {
//        self.init(biguint: BigUInt(source))
//    }
//
//    public init(integerLiteral value: BigUInt.IntegerLiteralType) {
//        self.init(biguint: BigUInt(integerLiteral: value))
//    }
//
//    public init<T>(_ source: T) where T : BinaryFloatingPoint {
//        self.init(biguint: BigUInt(source))
//    }
//
//    public init?<T>(exactly source: T) where T : BinaryInteger {
//        if let v = BigUInt(exactly: source) {
//            self.init(biguint: v)
//        } else {
//            return nil
//        }
//    }
//
//    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
//        if let v = BigUInt(exactly: source) {
//            self.init(biguint: v)
//        } else {
//            return nil
//        }
//    }
//
//    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
//        self.init(biguint: BigUInt(truncatingIfNeeded: source))
//    }
//
//    public init<T>(clamping source: T) where T : BinaryInteger {
//        self.init(biguint: BigUInt(clamping: source))
//    }
//
//    public static prefix func ~ (x: UInt256) -> UInt256 {
//        return Self(biguint: ~x.value)
//    }
//
//    public static func + (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value + rhs.value)
//    }
//
//    public static func - (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value - rhs.value)
//    }
//
//    public static func * (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value * rhs.value)
//    }
//
//    public static func / (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value / rhs.value)
//    }
//
//    public static func % (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value % rhs.value)
//    }
//
//    public static func & (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value & rhs.value)
//    }
//
//    public static func | (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value | rhs.value)
//    }
//
//    public static func ^ (lhs: UInt256, rhs: UInt256) -> UInt256 {
//        return Self(biguint: lhs.value ^ rhs.value)
//    }
//
//    public static func += (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value += rhs.value
//    }
//
//    public static func -= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value -= rhs.value
//    }
//
//    public static func /= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value /= rhs.value
//    }
//
//    public static func *= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value *= rhs.value
//    }
//
//    public static func %= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value %= rhs.value
//    }
//
//    public static func &= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value &= rhs.value
//    }
//
//    public static func |= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value |= rhs.value
//    }
//
//    public static func ^= (lhs: inout UInt256, rhs: UInt256) {
//        lhs.value ^= rhs.value
//    }
//}
//
