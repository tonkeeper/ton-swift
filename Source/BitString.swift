import Foundation

struct BitString {
    
    static let empty = BitString(data: .init(), offset: 0, length: 0)
    
    private let _offset: Int
    private let _length: Int
    private let _data: Data
    
    /**
     - returns the length of the bitstring
     */
    var length: Int {
        return _length
    }
    
    /**
     Constructing BitString from a buffer
     
     - Parameter data: data that contains the bitstring data. NOTE: We are expecting this buffer to be NOT modified
     - Parameter offset: offset in bits from the start of the buffer
     - Parameter length: length of the bitstring in bits
     */
    init(data: Data, offset: Int, length: Int) {
        guard length > 0 else {
            fatalError("Length \(length) is out of bounds")
        }
        
        self._offset = offset
        self._length = length
        self._data = data
    }

    /**
     Returns the bit at the specified index
     
     - Parameter index:index of the bit
     - throws error: if index is out of bounds
     - returns true if the bit is set, false otherwise
     */
    func at(index: Int) throws -> Bool {
        guard index <= _length else {
//            throw new Error(`Index ${index} > ${this._length} is out of bounds`);
            throw NSError()
        }
        guard index >= 0 else {
//            throw new Error(`Index ${index} < 0 is out of bounds`);
            throw NSError()
        }
        
        let byteIndex = (_offset + index) >> 3
        let bitIndex = 7 - ((_offset + index) % 8) // NOTE: We are using big endian
        
        return (_data[byteIndex] & (1 << bitIndex)) != 0
    }
    
    /**
     Get a subscring of the bitstring
     
     - Parameter offset: offset in bits from the start of the buffer
     - Parameter length: length of the bitstring in bits
     - returns substring of bitstring
     */
    func substring(offset: Int, length: Int) throws -> BitString {
        // Corner case of empty string
        if length == 0 && offset == _length {
            return BitString.empty
        }
        
        try checkOffset(offset: offset, length: length)
        
        return BitString(data: _data, offset: _offset + offset, length: length)
    }
    
    /**
     Get a subscring of the bitstring
     
     - Parameter offset: offset in bits from the start of the buffer
     - Parameter length: length of the bitstring in bits
     - returns buffer if the bitstring is aligned to bytes, null otherwise
     */
    func subbuffer(offset: Int, length: Int) throws -> Data? {
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
        return _data.subdata(in: start...end)//this._data.subarray(start, end)
    }
    
    /**
     Format to canonical string
     
     - returns formatted bits as a string
     */
    func toString() throws -> String {
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
        if offset >= _length {
//            throw new Error(`Offset ${offset} is out of bounds`);
            throw NSError()
        }
        if offset < 0 {
//            throw new Error(`Offset ${offset} is out of bounds`);
            throw NSError()
        }
        if offset + length > _length {
//            throw new Error(`Offset + Lenght = ${offset + length} is out of bounds`);
            throw NSError()
        }
    }
    
}

// MARK: - Equatable
extension BitString: Equatable {
    static func == (lhs: BitString, rhs: BitString) -> Bool {
        return lhs._data == rhs._data &&
               lhs._length == rhs._length &&
               lhs._offset == rhs._offset
    }
}

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound)
    }
}
