import Foundation

class BitBuilder {
    private var _buffer: Data
    private var _length: Int
    
    /**
     - returns the length of the bitstring
     */
    var length: Int {
        return _length
    }
    
    init(size: Int = 1023) {
//        _buffer = Data(count: Int(ceil(Double(size) / 8.0)))
        _buffer = Data(count: (size + 7) / 8)
        _length = 0
    }
    
    /**
     Write a single bit
     
     - Parameter value: bit to write, positive number for 1, zero or negative for 0
     */
    func writeBit(value: Int) throws {
        let n = _length
        if n > _buffer.count * 8 {
            //            throw new Error("BitBuilder overflow");
            throw NSError()
        }
        
        if value > 0 {
            _buffer[(n / 8) | 0] |= 1 << (7 - (n % 8));
//            _buffer[_length / 8] |= 1 << (7 - (_length % 8));
        }
        
        _length += 1
    }
    
    /**
     Write a single bit
     
     - Parameter value: bit to write, true for 1, false for 0
     */
    func writeBit(value: Bool) throws {
        try writeBit(value: value ? 1 : 0)
    }
    
    /**
     Copy bits from BitString
     
     - Parameter src: source bits
     */
    func writeBits(src: BitString) throws {
        for i in 0..<src.length {
            try writeBit(value: src.at(index: i))
        }
    }
    
    /**
     Build BitString
     
     - returns result bit string
     */
    func build() throws -> BitString {
        return BitString(data: _buffer, offset: 0, length: _length)
    }
    
    func buffer() throws -> Data {
        if _length % 8 != 0 {
//            throw new Error("BitBuilder buffer is not byte aligned");
            throw NSError()
        }
        
        return _buffer.subdata(in: 0..._length / 8)
    }
}
