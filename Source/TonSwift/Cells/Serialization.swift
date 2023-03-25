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

/*
/// Represents a description of a type for serialization.
/// This protocol should be implemented by "type descriptors", or meta-types, not the actual value types.
public protocol TypeSerialization {
    /// Type of the returned value
    associatedtype ValueType
    
    ///
    var bits: Int { get }
    func write(value: ValueType, to: Builder) throws
    func read(from: Slice) throws -> ValueType
}

/// Type description for "self-contained" types that do know their size statically.
/// Simple types such as `Address` or `Data` store their sizes,
/// but integers require either explicit wrapper that contains bit-size, or a custom `TypeSerialization` descriptor.
public struct StaticType: TypeSerialization {
    
}
*/

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
