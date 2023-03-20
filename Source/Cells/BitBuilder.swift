import Foundation
import BigInt

/// Interface for writing bits to a BitString.
public class BitBuilder {
    
    /// Maximum length of the bitstring in bits
    let capacity: Int
    
    private var _buffer: Data
    private var _length: Int
    
    /// Number of bits written
    public var length: Int {
        return _length
    }
    
    /// Remaining bits available
    public var availableBits: Int {
        return capacity - _length
    }
    
    /// Returns whether the written bits are byte-aligned
    public var aligned: Bool {
        return _length % 8 == 0
    }
    
    /// Initialize the BitBuilder with a given capacity.
    /// The backing buffer will be allocated right away, so the capacity is limited to 64Kbit at the API level.
    public init(capacity: UInt16 = 1023) {
        let cap = Int(capacity)
        _buffer = Data(count: (cap + 7) / 8)
        _length = 0
        self.capacity = cap
    }
    
    
    /// Write a single bit: the bit is set for positive values, not set for zero or negative
    public func write(bit: Int) throws {
        try checkCapacity(1)
        
        if bit > 0 {
            _buffer[_length / 8] |= 1 << (7 - (_length % 8))
        }
        
        _length += 1
    }
    
    /// Writes bit as a boolean (true => 1, false => 0)
    public func write(bit: Bool) throws {
        try write(bit: bit ? 1 : 0)
    }
    
    /// Writes bits from a bitstring
    public func write(bits: BitString) throws {
        for i in 0..<bits.length {
            try write(bit: bits.at(index: i))
        }
    }
    
    /// Writes bytes from the src data.
    func write(data: Data) throws {
        try checkCapacity(data.count*8)
        
        // Special case for aligned offsets
        if aligned {
            for i in 0..<data.count {
                _buffer[_length / 8 + i] = data[i]
            }
            _length += data.count * 8
        } else {
            for i in 0..<data.count {
                try write(uint: data[i], bits: 8)
            }
        }
    }
    
    /**
     Write uint value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    */
    public func write<T>(uint value: T, bits: Int) throws where T: BinaryInteger {
        return try write(biguint: BigInt(value), bits: bits);
    }
    
    public func write(biguint value: BigInt, bits: Int) throws {
        try checkCapacity(bits)
        
        // Special cases when our buffer is aligned
        if aligned {
            // Special case for 8 bits
            if bits == 8 {
                let v = Int(value)
                if v < 0 || v > 255 {
                    throw TonError.custom("Value is out of range for \(bits) bits. Got \(value)")
                }
                
                _buffer[_length / 8] = UInt8(value)
                _length += 8
                
                return
            }
            
            // Special case for 16 bits
            if bits == 16 {
                let v = Int(value)
                if v < 0 || v > 65536 {
                    throw TonError.custom("Value is out of range for \(bits) bits. Got \(value)")
                }
                _buffer[_length / 8] = UInt8(v >> 8)
                _buffer[_length / 8 + 1] = UInt8(v & 0xff)
                _length += 16
                
                return
            }
        }
        
        // Corner case for zero bits
        if bits == 0 {
            if value != 0 {
                throw TonError.custom("value is not zero for \(bits) bits. Got \(value)")
            } else {
                return
            }
        }
        
        // Generic case
        var v = value
        
        // Check input
        let vBits = (BigInt(1) << BigInt(bits))
        if v < 0 || v >= vBits {
            throw TonError.custom("BitLength is too small for a value \(value). Got \(bits)")
        }
        
        // Convert number to bits
        var b: [Bool] = []
        while v > 0 {
            b.append(v % 2 == 1)
            v /= 2
        }
        
        // Write bits
        for i in 0..<bits {
            let off = bits - i - 1
            if (off < b.count) {
                try write(bit: b[off])
            } else {
                try write(bit: false)
            }
        }
    }
    
    /**
     Write int value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    */
    func writeInt(_ value: Any, bits: Int) throws {
        var v: BigInt
        if let value = value as? BigInt {
            v = value
        } else if let value = value as? Int {
            v = BigInt(value)
        } else if let value = value as? any BinaryInteger {
            v = BigInt(value)
        } else {
            throw TonError.custom("Invalid value. Got \(value)")
        }
        if bits < 0 {
            throw TonError.custom("Invalid bit length. Got \(bits)")
        }
        
        if bits == 0 {
            if v != 0 {
                throw TonError.custom("Value is not zero for \(bits) bits. Got \(v)")
            } else {
                return
            }
        }
        
        if bits == 1 {
            if v != -1 && v != 0 {
                throw TonError.custom("Value is not zero or -1 for \(bits) bits. Got \(v)")
            } else {
                try write(bit: v == -1)
                return
            }
        }
        
        let vBits = 1 << (bits - 1)
        if v < -vBits || v >= vBits {
            throw TonError.custom("Value is out of range for \(bits) bits. Got \(v)")
        }
        
        if v < 0 {
            try write(bit: true)
            v = (1 << (bits - 1)) + v
        } else {
            try write(bit: false)
        }
        
        try write(uint: v, bits: bits - 1)
    }
    
    /**
     Write coins in var uint format
     - parameter amount: amount to write
    */
    func writeCoins(coins: Coins) throws {
        try writeVarUint(value: coins.amount, bits: 4)
    }
        
    /**
     Wrtie var uint value, used for serializing coins
    - parameter value: value to write as bigint or number
    - parameter bits: header bits to write size
    */
    func writeVarUint(value: UInt64, bits: Int) throws {
        try writeVarUint(value: BigUInt(value), bits: bits)
    }
    func writeVarUint(value: BigUInt, bits: Int) throws {
        let v = BigUInt(value)
        if bits < 0 {
            throw TonError.custom("Invalid bit length. Got \(bits)")
        }
        if v < 0 {
            throw TonError.custom("Value is negative. Got \(value)")
        }

        // Corner case for zero
        if v == 0 {
            // Write zero size
            try write(uint: 0, bits: bits)
            return
        }

        // Calculate size
        let sizeBytes = Int(ceil(Double(v.bitWidth) / 8.0))
        let sizeBits = sizeBytes * 8

        // Write size
        try write(uint: sizeBytes, bits: bits)

        // Write number
        try write(uint: v, bits: sizeBits)
    }
    
    /// Converts builder into BitString
    public func build() throws -> BitString {
        return BitString(data: _buffer, unchecked:(offset: 0, length: _length))
    }
    
    /// Converts to data if the bitstring contains a whole number of bytes.
    public func toData() throws -> Data {
        if !aligned {
            throw TonError.custom("BitBuilder buffer is not byte-aligned")
        }
        return _buffer.subdata(in: 0..._length / 8)
    }

    private func checkCapacity(_ bits: Int) throws {
        if availableBits < bits || bits < 0 {
            throw TonError.custom("BitBuilder overflow: need to write \(bits), but available \(availableBits)")
        }
    }

}
