import Foundation

extension Data {
    var bytes: Data {
        Data(map({ UInt8($0) }))
    }
}
