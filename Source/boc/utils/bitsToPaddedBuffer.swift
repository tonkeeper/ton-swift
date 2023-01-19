import Foundation

func bitsToPaddedBuffer(bits: BitString) throws -> Data {
    let builder = BitBuilder(size: (bits.length + 7) / 8 * 8)
    try builder.writeBits(src: bits)

    let padding = (bits.length + 7) / 8 * 8 - bits.length
    for i in 0..<padding {
        if i == 0 {
            try builder.writeBit(value: true)
        } else {
            try builder.writeBit(value: false)
        }
    }
    
    return try builder.buffer()
}
