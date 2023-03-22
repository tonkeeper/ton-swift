import Foundation

public struct BitString: Hashable {
    
    public static let empty = BitString(data: .init(), unchecked: (offset: 0, length: 0))
    
    private let _offset: Int
    private let _length: Int
    private let _data: Data
    
    /**
     - returns the length of the bitstring in bits
     */
    public var length: Int { _length }
    
    /**
     Constructing BitString from a buffer with specified offset and length without checking consistency.
     
     - parameter data: data that contains the bitstring data. NOTE: We are expecting this buffer to be NOT modified
     - parameter `unchecked.offset`: offset in bits from the start of the buffer
     - parameter `unchecked.length`: length of the bitstring in bits
     */
    public init(data: Data, offset: Int, length: Int) throws {
        guard offset >= 0 else {
            throw TonError.custom("Offset cannot be negative")
        }
        guard length >= 0 else {
            throw TonError.custom("Length cannot be negative")
        }
        guard (offset + length) > data.count * 8 else {
            throw TonError.custom("Offset and length out of bounds for the data")
        }
        self._data = data
        self._offset = offset
        self._length = length
    }
    
    /**
     Constructing BitString from a buffer with specified offset and length without checking consistency.
     
     - parameter data: data that contains the bitstring data. NOTE: We are expecting this buffer to be NOT modified
     - parameter `unchecked.offset`: offset in bits from the start of the buffer
     - parameter `unchecked.length`: length of the bitstring in bits
     */
    public init(data: Data, unchecked: (offset: Int, length: Int)) {
        self._data = data
        self._offset = unchecked.offset
        self._length = unchecked.length
    }
    
    /// Constructs BitString from a buffer of data
    public init(data: Data) {
        self._data = data
        self._offset = 0
        self._length = data.count * 8
    }

    /**
     Returns the bit at the specified index
     
     - parameter index:index of the bit
     - throws error: if index is out of bounds
     - returns true if the bit is set, false otherwise
     */
    public func at(_ index: Int) throws -> Bool {
        guard index <= _length && index >= 0 else {
            throw TonError.indexOutOfBounds(index)
        }
        
        return uncheckedAt(index)
    }
    
    private func uncheckedAt(_ index: Int) -> Bool {
        let byteIndex = (_offset + index) >> 3
        let bitIndex = 7 - ((_offset + index) % 8) // NOTE: We are using big endian
        
        return (_data[byteIndex] & (1 << bitIndex)) != 0
    }
    
    /**
     Get a subscring of the bitstring
     
     - parameter offset: offset in bits from the start of the buffer
     - parameter length: length of the bitstring in bits
     - returns substring of bitstring
     */
    public func substring(offset: Int, length: Int) throws -> BitString {
        // Corner case of empty string
        if length == 0 && offset == _length {
            return BitString.empty
        }
        
        try checkOffset(offset: offset, length: length)
        
        return BitString(data: _data, unchecked:(offset: _offset + offset, length: length))
    }
    
    /**
     Get a subscring of the bitstring
     
     - parameter offset: offset in bits from the start of the buffer
     - parameter length: length of the bitstring in bits
     - returns buffer if the bitstring is aligned to bytes, null otherwise
     */
    public func subbuffer(offset: Int, length: Int) throws -> Data? {
        try checkOffset(offset: offset, length: length)
        
        // Check alignment
        if length % 8 != 0 {
            return nil
        }
        if (_offset + offset) % 8 != 0 {
            return nil
        }

        // Create substring
        let start = ((_offset + offset) >> 3)
        let end = start + (length >> 3)
        
        return _data.subdata(in: start...end)
    }
    
    /// Formats the bitstring as a hex-encoded string with a `_` trailing symbol indicating `10*` padding to 4-bit alignment.
    public func toHex() throws -> String {
        let padded = Data(try self.bitsToPaddedBuffer())
        
        if _length % 4 == 0 {
            let s = padded[0..<(self._length + 7) / 8].hexString().uppercased()
            if _length % 8 == 0 {
                return s
            } else {
                return String(s.prefix(s.count - 1))
            }
        } else {
            let hex = padded.hexString().uppercased()
            if _length % 8 <= 4 {
                return String(hex.prefix(hex.count - 1)) + "_"
            } else {
                return hex + "_"
            }
        }
    }
    
    /// Formats the bitstring in binary digits.
    public func toBinary() -> String {
        var s = ""
        for i in 0..<length {
            s.append(uncheckedAt(i) ? "1" : "0")
        }
        return s
    }
    
    /// Formats the bitstring as a hex-encoded string with a `_` trailing symbol indicating `10*` padding to 4-bit alignment.
    public func toString() throws -> String {
        return try toHex()
    }
    
    private func checkOffset(offset: Int, length: Int) throws {
        if offset >= _length || offset < 0 || offset + length > _length {
            throw TonError.offsetOutOfBounds(offset)
        }
    }
    
    
    public func bitsToPaddedBuffer() throws -> Data {
        let builder = BitBuilder(capacity: UInt16((self.length + 7) / 8 * 8))
        try builder.write(bits: self)

        let padding = (self.length + 7) / 8 * 8 - self.length
        for i in 0..<padding {
            if i == 0 {
                try builder.write(bit: true)
            } else {
                try builder.write(bit: false)
            }
        }
        
        return try builder.toData()
    }

}

extension BitString: Equatable {
    
    /**
     Checks for equality
    - parameter lhs: bitstring
    - parameter rhs: bitstring
    - returns true if the bitstrings are equal, false otherwise
     */
    public static func == (lhs: BitString, rhs: BitString) -> Bool {
        if lhs._length != rhs._length {
            return false
        }
        
        do {
            for i in 0..<lhs._length {
                let lhsI = try lhs.at(i)
                let rhsI = try rhs.at(i)
                
                if lhsI != rhsI {
                    return false
                }
            }
        } catch {
            return false
        }
        
        return true
    }
}

extension Data {
    public func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound)
    }
    
    public func hexString() -> String {
        map({ String(format: "%02hhx", $0) }).joined()
    }
}
