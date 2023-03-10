import Foundation

func getRefsDescriptor(refs: [Cell], level: UInt32, type: CellType) -> UInt8 {
    let typeFactor: UInt8 = type != .ordinary ? 1 : 0
    return UInt8(refs.count) + typeFactor * 8 + UInt8(level) * 32
}

func getBitsDescriptor(bits: BitString) -> UInt8 {
    let len = bits.length
    return UInt8(ceil(Double(len) / 8) + floor(Double(len) / 8))
}

func getRepr(bits: BitString, refs: [Cell], level: UInt32, type: CellType) throws -> Data {
    // Allocate
    let bitsLen = (bits.length + 7) / 8
    var repr = Data(count: 2 + bitsLen + (2 + 32) * refs.count)

    // Write descriptors
    var reprCursor = 0
    repr[reprCursor] = getRefsDescriptor(refs: refs, level: level, type: type)
    reprCursor += 1
    repr[reprCursor] = getBitsDescriptor(bits: bits)
    reprCursor += 1

    // Write bits
    repr.replaceSubrange(reprCursor..<reprCursor + bitsLen, with: try bits.bitsToPaddedBuffer())
    reprCursor += bitsLen

    // Write refs
    for c in refs {
        var childDepth: UInt32
        if type == .merkleProof || type == .merkleUpdate {
            childDepth = c.depth(level: Int(level) + 1)
        } else {
            childDepth = c.depth(level: Int(level))
        }
        repr[reprCursor] = UInt8(floor(Double(childDepth) / 256))
        reprCursor += 1
        repr[reprCursor] = UInt8(childDepth % 256)
        reprCursor += 1
    }
    for c in refs {
        var childHash: Data
        if type == .merkleProof || type == .merkleUpdate {
            childHash = c.hash(level: Int(level) + 1)
        } else {
            childHash = c.hash(level: Int(level))
        }
        
        for i in 0..<32 {
            repr[reprCursor + i] = childHash[i]
        }
        
        reprCursor += 32
    }

    return repr
}
