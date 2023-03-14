import Foundation

extension Slice {
    /// Load snake-encoded String
    public func loadStringTail() throws -> String {
        return try readString(slice: self)
    }
}

/// TBD: this looks like a snake encoding - should rename accordingly
func readSnakeData(slice: Slice) throws -> Data {
    // Check consistency
    if slice.remainingBits % 8 != 0 {
        throw TonError.custom("Invalid string length: \(slice.remainingBits)")
    }
    if slice.remainingRefs != 0 && slice.remainingRefs != 1 {
        throw TonError.custom("Invalid number of refs: \(slice.remainingRefs)")
    }
    if slice.remainingRefs == 1 && (1023 - slice.remainingBits) > 7 {
        throw TonError.custom("Invalid string length: \(slice.remainingBits / 8)")
    }

    // Read string
    var res = Data()
    if slice.remainingBits == 0 {
        res = Data()
    } else {
        res = try slice.bits.loadBuffer(bytes: slice.remainingBits / 8)
    }

    // Read tail
    if slice.remainingRefs == 1 {
        res.append(try readSnakeData(slice: slice.loadRef().beginParse()))
    }

    return res
}

func readString(slice: Slice) throws -> String {
    guard let str = String(data: try readSnakeData(slice: slice), encoding: .utf8) else {
        throw TonError.custom("Cannot read slice to string")
    }
    
    return str
}

func writeSnakeBuffer(src: Data, builder: Builder) throws {
    if src.count > 0 {
        let bytes = Int(floor(Double(builder.availableBits / 8)))
        if src.count > bytes {
            let a = src.subdata(in: 0..<bytes)
            let t = src.subdata(in: bytes..<src.endIndex)
            try builder.storeBuffer(a)
            let bb = Builder()
            try writeSnakeBuffer(src: t, builder: bb)
            try builder.storeRef(cell: bb.endCell())
        } else {
            try builder.storeBuffer(src)
        }
    }
}

func stringToCell(src: String) throws -> Cell {
    let builder = Builder()
    try writeSnakeBuffer(src: Data(src.utf8), builder: builder)
    
    return try builder.endCell()
}

func writeString(src: String, builder: Builder) throws {
    try writeSnakeBuffer(src: Data(src.utf8), builder: builder)
}
