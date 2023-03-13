import Foundation
import BigInt

class BitReader {
    private var _bits: BitString
    private var _offset: Int
    
    public init(bits: BitString, offset: Int = 0) {
        _bits = bits
        _offset = offset
    }

    /// Number of bits remaining
    public var remaining: Int { _bits.length - _offset }

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

    /**
     Load buffer
     - parameter bytes: number of bytes
     - returns new buffer
    */
    public func loadBuffer(bytes: Int) throws -> Data {
        let buf = try _preloadBuffer(bytes: bytes, offset: _offset)
        _offset += bytes * 8
        
        return buf
    }

    /**
     Preload buffer
    - parameter bytes: number of bytes
    - returns new buffer
    */
    public func preloadBuffer(bytes: Int) throws -> Data {
        return try _preloadBuffer(bytes: bytes, offset: _offset)
    }

    /**
     Load uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func loadUint(bits: Int) throws -> UInt32 {
        return UInt32(try loadUintBig(bits: bits))
    }
    
    /**
     Load uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func loadUintBig(bits: Int) throws  -> UInt32 {
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
        let loaded = try _preloadInt(bits: bits, offset: _offset)
        _offset += bits
        
        return loaded
    }

    /**
     Preload uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func preloadUint(bits: Int) throws -> UInt32 {
        return UInt32(try _preloadUint(bits: bits, offset: _offset))
    }

    /**
     Preload uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func preloadUintBig(bits: Int) throws -> UInt32 {
        return try _preloadUint(bits: bits, offset: _offset)
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
    func loadVarUint(bits: Int) throws -> UInt32 {
        let size = Int(try loadUint(bits: bits))
        return try loadUintBig(bits: size * 8)
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
    func preloadVarUint(bits: Int) throws -> UInt32 {
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
    
    /**
     Load coins value
    - returns read value as bigint
    */
    func loadCoins() throws -> Coins {
        return Coins(amount: try loadVarUintBig(bits: 4))
    }
    
    /**
     Preload coins value
    - returns read value as bigint
    */
    func preloadCoins() throws -> Coins {
        return Coins(amount: try preloadVarUintBig(bits: 4))
    }
    
    /**
     Load Address
    - returns Address
    */
    func loadAddress() throws -> Address {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type == 2 {
            return try _loadInternalAddress()
        } else {
            throw TonError.custom("Invalid address: \(type)")
        }
    }
    
    /**
     Load internal address
    - returns Address or nil
    */
    func loadMaybeAddress() throws -> Address? {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type == 0 {
            _offset += 2
            return nil
            
        } else if type == 2 {
            return try _loadInternalAddress()
        } else {
            throw TonError.custom("Invalid address")
        }
    }
    
    /**
     Load external address
    - returns ExternalAddress
    */
    func loadExternalAddress() throws -> ExternalAddress {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type == 1 {
            return try _loadExternalAddress()
        } else {
            throw TonError.custom("Invalid address")
        }
    }
    
    /**
     Load external address
    - returns ExternalAddress or nil
    */
    func loadMaybeExternalAddress() throws -> ExternalAddress? {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type == 0 {
            _offset += 2;
            return nil
            
        } else if type == 1 {
            return try _loadExternalAddress()
        } else {
            throw TonError.custom("Invalid address")
        }
    }

    // MARK: - Private methods
    
    /**
     Preload int from specific offset
    - parameter bits: bits to preload
    - parameter offset: offset to start from
    - returns read value as bigint
    */
    private func _preloadInt(bits: Int, offset: Int) throws -> BigInt {
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

    
    private func _preloadInt64(bits: Int, offset: Int) throws -> BigInt {
        guard bits != 0 else { return 0 }
        
        let sign = try _bits.at(index: offset)
        var res = BigInt(0)
        for i in 0..<bits - 1 {
            if try _bits.at(index: offset + 1 + i) {
                res += 1 << BigInt(bits - i - 1 - 1)
            }
        }
        
        if sign {
            res = res - (1 << BigInt(bits - 1))
        }
        
        return res
    }
    
    private func _preloadUint(bits: Int, offset: Int) throws -> UInt32 {
        guard bits != 0 else { return 0 }
        
        var res = UInt32(0)
        for i in 0..<bits {
            if try _bits.at(index: offset + i) {
                res += 1 << UInt32(bits - i - 1)
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
    
    private func _loadInternalAddress() throws -> Address {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type != 2 {
            throw TonError.custom("Invalid address")
        }

        // No Anycast supported
        if try _preloadUint(bits: 1, offset: _offset + 2) != 0 {
            throw TonError.custom("Invalid address")
        }

        // Read address
        let wc = Int8(try _preloadInt(bits: 8, offset: _offset + 3))
        let hash = try _preloadBuffer(bytes: 32, offset: _offset + 11)

        // Update offset
        self._offset += 267

        return Address(workchain: wc, hash: hash)
    }
    
    private func _loadExternalAddress() throws -> ExternalAddress {
        let type = try _preloadUint(bits: 2, offset: _offset)
        if type != 1 {
            throw TonError.custom("Invalid address")
        }
        
        // Load length
        let bits = Int(try _preloadUint(bits: 9, offset: _offset + 2))
        
        // Load address
        let value = BigInt(try _preloadUint(bits: bits, offset: _offset + 11))
        
        // Update offset
        _offset += 11 + bits
        
        return ExternalAddress(value: value, bits: bits)
    }
}
