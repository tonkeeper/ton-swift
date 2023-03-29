import Foundation

/// Types implementing both reading and writing
public protocol CellCodable {
    func writeTo(builder: Builder) throws
    static func readFrom(slice: Slice) throws -> Self
}

/// Types implement KnownSize protocol when they have statically-known size in bits
public protocol StaticSize {
    /// Size of the type in bits
    static var bitWidth: Int { get }
}

/// Every type that can be used as a dictionary value has an accompanying coder object configured to read that type.
/// This protocol allows implement dependent types because the exact instance would have runtime parameter such as bitlength for the values of this type.
public protocol TypeCoder {
    associatedtype T
    func serialize(src: T, builder: Builder) throws
    func parse(src: Slice) throws -> T
}

extension CellCodable {
    static func defaultCoder() -> some TypeCoder {
        DefaultCoder<Self>()
    }
}

public class DefaultCoder<X: CellCodable>: TypeCoder {
    public typealias T = X
    public func serialize(src: T, builder: Builder) throws {
        try src.writeTo(builder: builder)
    }
    public func parse(src: Slice) throws -> T {
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


public class BytesCoder: TypeCoder {
    public typealias T = Data
    let size: Int
    
    init(size: Int) {
        self.size = size
    }
    
    public func serialize(src: T, builder: Builder) throws {
        try builder.write(data: src)
    }
    public func parse(src: Slice) throws -> T {
        return try src.loadBytes(self.size)
    }
}

// Cell is encoded as a separate ref
extension Cell: CellCodable {
    public func writeTo(builder: Builder) throws {
        try builder.storeRef(cell: self)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return try slice.loadRef()
    }
}

// Slice is encoded inline
extension Slice: CellCodable {
    public func writeTo(builder: Builder) throws {
        try builder.storeSlice(src: self)
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return slice.clone() as! Self
    }
}

// Builder is encoded inline
extension Builder: CellCodable {
    public func writeTo(builder: Builder) throws {
        try builder.storeSlice(src: endCell().beginParse())
    }
    
    public static func readFrom(slice: Slice) throws -> Self {
        return try slice.clone().asBuilder() as! Self
    }
}
