import Foundation
import BigInt
//
//func serializeInternalKey(value: Any) throws -> String {
//    if let value = value as? UInt64 {
//        return "u:\(value)"
//    } else if let value = value as? Int {
//        return "n:\(value)"
//    } else if let value = value as? BigInt {
//        return "b:\(value)"
//    } else if let value = value as? BigUInt {
//        return "U:\(value)"
//    } else if let value = value as? Address {
//        // TODO: should we serialize toRaw instead?
//        return "a:\(value.toString())"
//    } else if let value = value as? Data {
//        return "f:\(value.hexString())"
//    }
//
//    throw TonError.custom("Invalid key type")
//}
//
//func deserializeInternalKey(value: String) throws -> any Hashable {
//    let k = String(value.prefix(2))
//    let v = String(value.dropFirst(2))
//
//    if k == "n:" {
//        if let intValue = Int(v) {
//            return intValue
//        }
//
//    } else if k == "u:" {
//        if let uintValue = UInt64(v) {
//            return uintValue
//        }
//        
//    } else if k == "b:" {
//        if let bigIntValue = BigInt(v)  {
//            return bigIntValue
//        }
//        
//    } else if k == "U:" {
//        if let bigUIntValue = BigUInt(v)  {
//            return bigUIntValue
//        }
//
//    }else if k == "a:" {
//        if let addressValue = try? Address.parse(v) {
//            return addressValue
//        }
//
//    } else if k == "f:" {
//        if let dataValue = Data(hex: v) {
//            return dataValue
//        }
//    }
//
//    throw TonError.custom("Invalid key type: \(k)")
//}
