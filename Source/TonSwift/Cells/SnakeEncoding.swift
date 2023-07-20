import Foundation

extension Slice {
    /// Loads snake-encoded String.
    /// Fails if the string is malformed or not a valid UTF-8 string.
    public func loadSnakeString() throws -> String {
        guard let str = String(data: try loadSnakeData(), encoding: .utf8) else {
            throw TonError.custom("Cannot read slice to string")
        }
        return str
    }

    /// Loads snake-encoded Data. Fails if the binary string is malformed.
    public func loadSnakeData() throws -> Data {
        // Check consistency
        if remainingBits % 8 != 0 {
            throw TonError.custom("Invalid string length: \(remainingBits)")
        }
        if remainingRefs != 0 && remainingRefs != 1 {
            throw TonError.custom("Invalid number of refs: \(remainingRefs)")
        }
        if remainingRefs == 1 && (BitsPerCell - remainingBits) > 7 {
            throw TonError.custom("Invalid string length: \(remainingBits / 8)")
        }

        // Read string
        var res = Data()
        if remainingBits == 0 {
            res = Data()
        } else {
            res = try loadBytes(remainingBits / 8)
        }

        // Read tail
        if remainingRefs == 1 {
            res.append(
                try loadRef()
                    .beginParse()
                    .loadSnakeData()
            )
        }

        return res
    }
}

extension Builder {
    /// Writes snake-encoded data
    @discardableResult
    public func writeSnakeData(_ src: Data) throws -> Self {
        if src.count > 0 {
            let bytes = Int(floor(Double(availableBits / 8)))
            if src.count > bytes {
                let a = src.subdata(in: 0..<bytes)
                let t = src.subdata(in: bytes..<src.endIndex)
                try store(data: a)
                let cell = try (try Builder().writeSnakeData(t)).endCell()
                try store(ref:cell)
            } else {
                try store(data: src)
            }
        }
        return self
    }

    /// Writes snake-encoded UTF-8 string.
    public func writeSnakeString(_ src: String) throws -> Self {
        try writeSnakeData(Data(src.utf8))
    }
}

extension String {
    /// Encodes a String into a Cell
    public func toTonCell() throws -> Cell {
        try Builder().writeSnakeData(Data(utf8)).endCell()
    }
}

