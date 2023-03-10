import Foundation

/// Types implement this protocol to become writeable to Cells via Builder.
public protocol CellWritable {
    func writeTo(builder: Builder) throws;
}

//extension Optional where Wrapped: CellWritable {
//    func writeTo(builder: Builder) throws {
//        if let object = object {
//            try storeBit(true)
//            try store(object: object)
//        } else {
//            try storeBit(false)
//        }
//        
//        return self
//    }
//}
