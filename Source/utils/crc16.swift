import Foundation

func crc16(data: Data) -> Data {
    let poly: UInt32 = 0x1021
    var reg: UInt32 = 0
    var message = data
    message.append(0)
    message.append(0)
    
    for byte in message {
        var mask: UInt8 = 0x80
        while mask > 0 {
            reg <<= 1
            if byte & mask != 0 {
                reg += 1
            }
            
            mask >>= 1
            if reg > 0xffff {
                reg &= 0xffff
                reg ^= poly
            }
        }
    }
    
    let highByte = UInt8(reg / 256)
    let lowByte = UInt8(reg % 256)
    
    return Data([highByte, lowByte])
}
