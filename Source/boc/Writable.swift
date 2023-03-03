import Foundation

public protocol Writable {
    func writeTo(builder: Builder)
}
