import Foundation

func crc32c(source: Data) -> Data {
    let poly: UInt32 = 0x82f63b78
    var crc: UInt32 = 0 ^ 0xffffffff
    
    for i in 0..<source.count {
        crc ^= UInt32(source[i])
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
    }
    crc = crc ^ 0xffffffff

    var res = Data(count: 4)
    res.withUnsafeMutableBytes { (resPointer: UnsafeMutableRawBufferPointer) -> Void in
        resPointer.storeBytes(of: crc.littleEndian, as: UInt32.self)
    }
    
    return res
}
