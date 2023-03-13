import Foundation
import BigInt

class BitBuilder {
    private var _buffer: Data
    private var _length: Int
    
    /**
     - returns the length of the bitstring
     */
    public var length: Int {
        return _length
    }
    
    public init(size: Int = 1023) {
        _buffer = Data(count: (size + 7) / 8)
        _length = 0
    }
    
    // MARK: - Public methods
    
    /**
     Write a single bit
     - parameter value: bit to write, positive number for 1, zero or negative for 0
     */
    public func writeBit(value: Int) throws {
        if _length > _buffer.count * 8 {
            throw TonError.custom("BitBuilder overflow")
        }
        
        if value > 0 {
            _buffer[_length / 8] |= 1 << (7 - (_length % 8))
        }
        
        _length += 1
    }
    
    /**
     Write a single bit
     - parameter value: bit to write, true for 1, false for 0
     */
    public func writeBit(value: Bool) throws {
        try writeBit(value: value ? 1 : 0)
    }
    
    /**
     Copy bits from BitString
     - parameter src: source bits
     */
    public func writeBits(src: BitString) throws {
        for i in 0..<src.length {
            try writeBit(value: src.at(index: i))
        }
    }
    
    /**
     Build BitString
     - returns result bit string
     */
    public func build() throws -> BitString {
        return BitString(data: _buffer, unchecked:(offset: 0, length: _length))
    }
    
    /**
     Build into Buffer
    - returns result buffer
    */
    public func buffer() throws -> Data {
        if _length % 8 != 0 {
            throw TonError.custom("BitBuilder buffer is not byte aligned")
        }
        
        return _buffer.subdata(in: 0..._length / 8)
    }
    
    /**
     Write bits from buffer
    - parameter src: source buffer
    */
    func writeBuffer(src: Data) throws {
        // Special case for aligned offsets
        if _length % 8 == 0 {
            if _length + src.count * 8 > _buffer.count * 8 {
                throw TonError.custom("BitBuilder overflow")
            }
            
            for i in 0..<src.count {
                _buffer[_length / 8 + i] = src[i]
            }

            _length += src.count * 8
        } else {
            for i in 0..<src.count {
                try writeUint(value: BigInt(src[i]), bits: 8)
            }
        }
    }
    
    /**
     Write uint value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    */
    public func writeUint(value: UInt64, bits: Int) throws {
        try writeUint(value: BigInt(value), bits: bits)
    }
    public func writeUint(value: UInt32, bits: Int) throws {
        try writeUint(value: BigInt(value), bits: bits)
    }
    public func writeUint(value: BigUInt, bits: Int) throws {
        try writeUint(value: BigInt(value), bits: bits)
    }
    public func writeUint(value: BigInt, bits: Int) throws {
        // Special case for 8 bits
        if bits == 8 && _length % 8 == 0 {
            let v = Int(value)
            if v < 0 || v > 255 {
                throw TonError.custom("Value is out of range for \(bits) bits. Got \(value)")
            }
            
            _buffer[_length / 8] = UInt8(value)
            _length += 8
            
            return
        }
        
        // Special case for 16 bits
        if bits == 16 && _length % 8 == 0 {
            let v = Int(value)
            if v < 0 || v > 65536 {
                throw TonError.custom("Value is out of range for \(bits) bits. Got \(value)")
            }
            _buffer[_length / 8] = UInt8(v >> 8)
            _buffer[_length / 8 + 1] = UInt8(v & 0xff)
            _length += 16
            
            return
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
                try writeBit(value: b[off])
            } else {
                try writeBit(value: false)
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
                try writeBit(value: v == -1)
                return
            }
        }
        
        let vBits = 1 << (bits - 1)
        if v < -vBits || v >= vBits {
            throw TonError.custom("Value is out of range for \(bits) bits. Got \(v)")
        }
        
        if v < 0 {
            try writeBit(value: true)
            v = (1 << (bits - 1)) + v
        } else {
            try writeBit(value: false)
        }
        
        try writeUint(value: v, bits: bits - 1)
    }
    
    /**
     Write coins in var uint format
     - parameter amount: amount to write
    */
    func writeCoins(coins: Coins) throws {
        try writeVarUint(value: coins.amount, bits: 4)
    }
    
    /**
     Write address
    - parameter address: write address or address external
    */
    func writeAddress(address: Address?) throws {
        if let address = address {
            try writeUint(value: BigInt(2), bits: 2)
            try writeUint(value: BigInt(0), bits: 1)
            try writeInt(address.workchain, bits: 8)
            try writeBuffer(src: address.hash)
        } else {
            try writeUint(value: BigInt(0), bits: 2)
        }
    }
    func writeAddress(address: ExternalAddress?) throws {
        if let address = address {
            try writeUint(value: BigInt(1), bits: 2)
            try writeUint(value: BigInt(address.bits), bits: 9)
            try writeUint(value: BigInt(address.value), bits: address.bits)
        } else {
            try writeUint(value: BigInt(0), bits: 2)
        }
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
            try writeUint(value: UInt64(0), bits: bits)
            return
        }

        // Calculate size
        let sizeBytes = Int(ceil(Double(v.bitWidth) / 8.0))
        let sizeBits = sizeBytes * 8

        // Write size
        try writeUint(value: UInt32(sizeBytes), bits: bits)

        // Write number
        try writeUint(value: v, bits: sizeBits)
    }

}
