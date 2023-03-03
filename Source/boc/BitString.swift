import Foundation

public struct BitString: Hashable {
    
    static let empty = BitString(data: .init(), offset: 0, length: 0)
    
    private let _offset: Int
    private let _length: Int
    private let _data: Data
    
    /**
     - returns the length of the bitstring
     */
    public var length: Int { _length }
    
    /**
     Constructing BitString from a buffer
     
     - parameter data: data that contains the bitstring data. NOTE: We are expecting this buffer to be NOT modified
     - parameter offset: offset in bits from the start of the buffer
     - parameter length: length of the bitstring in bits
     */
    public init(data: Data, offset: Int, length: Int) {
        self._offset = max(0, offset)
        self._length = length
        self._data = data
    }

    /**
     Returns the bit at the specified index
     
     - parameter index:index of the bit
     - throws error: if index is out of bounds
     - returns true if the bit is set, false otherwise
     */
    public func at(index: Int) throws -> Bool {
        guard index <= _length && index >= 0 else {
            throw TonError.indexOutOfBounds(index)
        }
        
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
        
        return BitString(data: _data, offset: _offset + offset, length: length)
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
    
    /**
     Format to canonical string
     
     - returns formatted bits as a string
     */
    public func toString() throws -> String {
        let padded = Data(try bitsToPaddedBuffer(bits: self))
        
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
    
    private func checkOffset(offset: Int, length: Int) throws {
        if offset >= _length || offset < 0 || offset + length > _length {
            throw TonError.offsetOutOfBounds(offset)
        }
    }
    
}

// MARK: - Equatable
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
                let lhsI = try lhs.at(index: i)
                let rhsI = try rhs.at(index: i)
                
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
