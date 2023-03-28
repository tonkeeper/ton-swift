import Foundation

/// Types implement the `Writeable` protocol to become writeable to Cells via Builder.
public protocol Writable {
    func writeTo(builder: Builder) throws
}

/// Types implement the `Readable` protocol to become readable from Slices
public protocol Readable {
    static func readFrom(slice: Slice) throws -> Self
}

/// Types implementing both reading and writing
public protocol Codeable: Readable, Writable {
}

/// Types implement KnownSize protocol when they have statically-known size in bits
public protocol StaticSize {
    /// Size of the type in bits
    static var sizeInBits: Int { get }
}

/// Every type that can be used as a dictionary value has an accompanying coder object configured to read that type.
/// This protocol allows implement dependent types because the exact instance would have runtime parameter such as bitlength for the values of this type.
public protocol TypeCoder {
    associatedtype T: Codeable
    func serialize(src: T, builder: Builder) throws
    func parse(src: Slice) throws -> T
}

extension Codeable {
    static func defaultCoder() -> some TypeCoder {
        DefaultCoder<Self>()
    }
}

public class DefaultCoder<X: Codeable>: TypeCoder {
    typealias T = X
    func serialize(src: T, builder: Builder) throws {
        try src.writeTo(builder: builder)
    }
    func parse(src: Slice) throws -> T {
        return try T.readFrom(slice: src)
    }
}

public extension TypeCoder {
    /// Serializes type to Cell
    func serializeToCell(_ src: T) throws -> Cell {
        let b = Builder()
        try serialize(src: src, builder: b)
        return try b.endCell()
    }
}

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
