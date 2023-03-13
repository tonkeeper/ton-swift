import Foundation

/// Types implement the `Writeable` protocol to become writeable to Cells via Builder.
public protocol Writable {
    func writeTo(builder: Builder) throws
}

/// Types implement the `Readable` protocol to become readable from Slices
public protocol Readable {
    static func readFrom(slice: Slice) throws -> Self
}
