import Foundation

/// Types implement the `Writeable` protocol to become writeable to Cells via Builder.
public protocol Writable {
    func writeTo(builder: Builder) throws;
}

/// Types implement the `Readable` protocol to become readable from Slices
public protocol Readable {
    static func readFrom(slice: Slice) throws -> Self;
}

extension Optional where Wrapped: Writable {
    func writeTo(builder: Builder) throws {
        if let value = self {
            try builder.storeBit(true)
            try builder.store(value)
        } else {
            try builder.storeBit(false)
        }
    }
}

extension Optional where Wrapped: Readable {
    static func readFrom(slice: Slice) throws -> Self {
        if try slice.loadBit() {
            return try Wrapped.readFrom(slice: slice)
        } else {
            return nil
        }
    }
}
