import Foundation
import BigInt

/// Interface for reading bits from the Cell
public class BitReader {
    private var _bits: BitString
    private var _offset: Int
    
    public init(bits: BitString) {
        _bits = bits
        _offset = 0
    }
    
    private init(bits: BitString, offset: Int = 0) {
        _bits = bits
        _offset = offset
    }

    /// Number of bits remaining
    public var remaining: Int { _bits.length - _offset }

    /// Makes a copy of the BitReader at its current state.
    func clone() -> BitReader {
        return BitReader(bits: _bits, offset: _offset)
    }

    // MARK: - Public methods
    
    /// Advances cursor by the specified numbe rof bits.
    public func skip(_ bits: Int) throws {
        if bits < 0 || _offset + bits > _bits.length {
            throw TonError.custom("Index \(_offset + bits) is out of bounds")
        }
        _offset += bits
    }

    /// Load a single bit.
    public func loadBit() throws -> Bool {
        let r = try _bits.at(index: _offset)
        _offset += 1
        return r
    }
    
    /// Load a single bit as a boolean value.
    public func loadBoolean() throws -> Bool {
        return try loadBit()
    }

    /// Preload a single bit without advancing the cursor.
    public func preloadBit() throws -> Bool {
        return try _bits.at(index: _offset)
    }

    /// Loads the specified number of bits in a `BitString`.
    public func loadBits(_ bits: Int) throws -> BitString {
        let r = try _bits.substring(offset: _offset, length: bits)
        _offset += bits
        return r
    }

    /// Preloads the specified number of bits in a `BitString` without advancing the cursor.
    public func preloadBits(_ bits: Int) throws -> BitString {
        return try _bits.substring(offset: _offset, length: bits)
    }

    /// Loads whole number of bytes and returns standard `Data` object.
    public func loadBytes(_ bytes: Int) throws -> Data {
        let buf = try _preloadBuffer(bytes: bytes, offset: _offset)
        _offset += bytes * 8
        
        return buf
    }

    /// Preloads whole number of bytes and returns standard `Data` object without advancing the cursor.
    public func preloadBytes(_ bytes: Int) throws -> Data {
        return try _preloadBuffer(bytes: bytes, offset: _offset)
    }

    /**
     Load uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func loadUint(bits: Int) throws -> UInt64 {
        return UInt64(try loadUintBig(bits: bits))
    }
    
    /**
     Load uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func loadUintBig(bits: Int) throws  -> BigUInt {
        let loaded = try preloadUintBig(bits: bits)
        _offset += bits
        
        return loaded
    }
    
    /**
     Load int value
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadInt(bits: Int) throws -> Int {
        let loaded = try _preloadInt(bits: bits, offset: _offset)
        _offset += bits
        
        return Int(loaded)
    }
    
    /**
     Load int value as bigint
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadIntBig(bits: Int) throws -> BigInt {
        let loaded = try _preloadBigInt(bits: bits, offset: _offset)
        _offset += bits
        
        return loaded
    }

    /**
     Preload uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func preloadUint(bits: Int) throws -> UInt64 {
        return try _preloadUint(bits: bits, offset: _offset)
    }

    /**
     Preload uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func preloadUintBig(bits: Int) throws -> BigUInt {
        return try _preloadBigUint(bits: bits, offset: _offset)
    }
    
    /**
     Load bit string that was padded to make it byte alligned. Used in BOC serialization
    - parameter bytes: number of bytes to read
    */
    func loadPaddedBits(bits: Int) throws -> BitString {
        // Check that number of bits is byte alligned
        guard bits % 8 == 0 else {
            throw TonError.custom("Invalid number of bits")
        }
        
        // Skip padding
        var length = bits
        while true {
            if try _bits.at(index: _offset + length - 1) {
                length -= 1
                break
            } else {
                length -= 1
            }
        }
        
        // Read substring
        let substring = try _bits.substring(offset: _offset, length: length)
        _offset += bits
        
        return substring
    }
    
    /**
     Load varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
    */
    func loadVarUint(bits: Int) throws -> UInt64 {
        let size = Int(try loadUint(bits: bits))
        return try loadUint(bits: size * 8)
    }

    /**
     Load varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
    */
    func loadVarUintBig(bits: Int) throws -> BigUInt {
        let size = Int(try loadUint(bits: bits))
        return BigUInt(try loadUintBig(bits: size * 8))
    }

    /**
     Preload varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
    */
    func preloadVarUint(bits: Int) throws -> UInt64 {
        let size = Int(try _preloadUint(bits: bits, offset: _offset))
        return try _preloadUint(bits: size * 8, offset: _offset + bits)
    }

    /**
     Preload varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
    */
    func preloadVarUintBig(bits: Int) throws -> BigUInt {
        let size = Int(try _preloadUint(bits: bits, offset: _offset))
        return BigUInt(try _preloadUint(bits: size * 8, offset: _offset + bits))
    }
    
    /// Loads an optional boolean.
    public func loadMaybeBoolean() throws -> Bool? {
        if try loadBit() {
            return try loadBoolean()
        } else {
            return nil
        }
    }

    /**
     Load maybe uint
    - parameter bits number of bits to read
    - returns uint value or null
     */
    public func loadMaybeUint(bits: Int) throws -> UInt64? {
        if try loadBit() {
            return try loadUint(bits: bits)
        } else {
            return nil
        }
    }
    
    /**
     Load maybe uint
    - parameter bits number of bits to read
    - returns uint value or null
     */
    public func loadMaybeUintBig(bits: Int) throws -> BigUInt? {
        if try loadBit() {
            return try loadUintBig(bits: bits)
        } else {
            return nil
        }
    }

    
    /// Load coins value
    func loadCoins() throws -> Coins {
        return Coins(amount: try loadVarUintBig(bits: 4))
    }
    
    /// Preload coins value
    func preloadCoins() throws -> Coins {
        return Coins(amount: try preloadVarUintBig(bits: 4))
    }
    
    
    // MARK: - Private methods
    
    /**
     Preload int from specific offset
    - parameter bits: bits to preload
    - parameter offset: offset to start from
    - returns read value as bigint
    */
    private func _preloadBigInt(bits: Int, offset: Int) throws -> BigInt {
        if bits == 0 {
            return 0
        }
        
        let sign = try _bits.at(index: offset)
        var res = BigInt(0)
        for i in 0..<bits - 1 {
            if try _bits.at(index: offset + 1 + i) {
                res += BigInt(1) << BigInt(bits - i - 1 - 1)
            }
        }
        
        if sign {
            res = res - (BigInt(1) << BigInt(bits - 1))
        }
        
        return res
    }

    private func _preloadBigUint(bits: Int, offset: Int) throws -> BigUInt {
        guard bits != 0 else { return 0 }
        
        var res = BigUInt(0)
        for i in 0..<bits {
            if try _bits.at(index: offset + i) {
                res += 1 << BigUInt(bits - i - 1)
            }
        }
        
        return res
    }
    
    private func _preloadInt(bits: Int, offset: Int) throws -> Int64 {
        guard bits != 0 else { return 0 }
        
        let sign = try _bits.at(index: offset)
        var res = Int64(0)
        for i in 0..<bits - 1 {
            if try _bits.at(index: offset + 1 + i) {
                res += 1 << Int64(bits - i - 1 - 1)
            }
        }
        
        if sign {
            res = res - (1 << Int64(bits - 1))
        }
        
        return res
    }
    
    private func _preloadUint(bits: Int, offset: Int) throws -> UInt64 {
        guard bits != 0 else { return 0 }
        
        var res = UInt64(0)
        for i in 0..<bits {
            if try _bits.at(index: offset + i) {
                res += 1 << UInt64(bits - i - 1)
            }
        }
        
        return res
    }

    private func _preloadBuffer(bytes: Int, offset: Int) throws -> Data {
        if let fastBuffer = try _bits.subbuffer(offset: offset, length: bytes * 8) {
            return fastBuffer
        }
        
        var buf = Data(count: bytes)
        for i in 0..<bytes {
            buf[i] = UInt8(try _preloadUint(bits: 8, offset: offset + i * 8))
        }
        
        return buf
    }
}
