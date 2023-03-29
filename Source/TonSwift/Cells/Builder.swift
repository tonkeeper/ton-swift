import Foundation
import BigInt

public class Builder {
    public let capacity: Int
    private var _buffer: Data
    private var _length: Int
    
    public private(set) var refs: [Cell]
        
    /// Initialize the Builder with a given capacity.
    /// Note: Builder can be used to construct larger bitstrings, not only 1023-bit Cells. E.g. to build a BoC.
    public init(capacity: Int = BitsPerCell) {
        self.capacity = capacity
        _buffer = Data(count: (capacity + 7) / 8)
        _length = 0
        self.refs = []
    }
    
    public convenience init(_ bits: BitString) throws {
        self.init()
        try self.write(bits: bits)
    }
    
    private init(capacity: Int, buffer: Data, length: Int, refs: [Cell]) {
        self.capacity = capacity
        self._buffer = buffer
        self._length = length
        self.refs = refs
    }
    
    /// Clones slice at its current state.
    public func clone() -> Builder {
        return Builder(capacity: capacity, buffer: _buffer, length: _length, refs: refs)
    }
    
    
    /// Returns whether the written bits are byte-aligned
    public var aligned: Bool {
        return _length % 8 == 0
    }
    
    /// Number of written bits
    public var bitsCount: Int {
        return _length
    }
    
    /// Number of bits written
    public var length: Int {
        return _length
    }
    
    
    /// Number of references added to this cell
    public var refsCount: Int {
        return refs.count
    }
    
    /// Remaining bits available
    public var availableBits: Int {
        return capacity - bitsCount
    }
    
    /// Remaining refs available
    public var availableRefs: Int {
        return RefsPerCell - refsCount
    }
    
    /// Returns metrics for the currently stored data
    public var metrics: CellMetrics {
        return CellMetrics(bitsCount: bitsCount, refsCount: refsCount)
    }
    
    /// Returns metrics for the remaining space in the cell
    public var remainingMetrics: CellMetrics {
        return CellMetrics(bitsCount: availableBits, refsCount: availableRefs)
    }
    
    /// Tries to fit the cell with the given metrics and returns the remaining space.
    /// If the cell does not fit, returns `nil`.
    public func fit(_ cell: CellMetrics) -> CellMetrics? {
        if availableBits >= cell.bitsCount && availableRefs >= cell.refsCount {
            return CellMetrics(
                bitsCount: availableBits - cell.bitsCount,
                refsCount: availableRefs - cell.refsCount
            )
        } else {
            return nil
        }
    }
    
    /**
     Store int value
     - parameter value: value as bigint or number
     - parameter bits: number of bits to write
     - returns this builder
     */
    @discardableResult
    public func storeInt(_ value: Int, bits: Int) throws -> Self {
        try self.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigUInt, bits: Int) throws -> Self {
        try self.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigInt, bits: Int) throws -> Self {
        try self.writeInt(value, bits: bits)
        return self
    }
    
    /**
     Store uint value
     - parameter value: value as bigint or number
     - parameter bits: number of bits to write
     - returns this builder
     */
    @discardableResult
    public func storeUint(_ value: UInt64, bits: Int) throws -> Self {
        try self.write(uint: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigUInt, bits: Int) throws -> Self {
        try self.write(uint: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigInt, bits: Int) throws -> Self {
        try self.write(uint: value, bits: bits)
        return self
    }
    
    /**
     Store varuint value
     - parameter value: value as bigint or number
     - parameter bits: number of bits to write to header
     - returns this builder
     */
    @discardableResult
    public func storeVarUint(value: UInt64, bits: Int) throws -> Self {
        try self.writeVarUint(value: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeVarUint(value: BigUInt, bits: Int) throws -> Self {
        try self.writeVarUint(value: value, bits: bits)
        return self
    }
    
    /**
     * Store coins value
     * @param amount amount of coins
     * @returns this builder
     */
    @discardableResult
    public func storeCoins(coins: Coins) throws -> Self {
        try self.writeCoins(coins: coins)
        return self
    }
    
    /**
     * Store maybe coins value
     * @param amount amount of coins, null or undefined
     * @returns this builder
     */
    @discardableResult
    public func storeMaybeCoins(coins: Coins?) throws -> Self {
        if let coins {
            try write(bit: true)
            try storeCoins(coins: coins)
        } else {
            try write(bit: false)
        }
        
        return self
    }
    
    /**
     Store reference
     - parameter cell: cell or builder to store
     - returns this builder
     */
    @discardableResult
    public func storeRef(cell: Cell) throws -> Self {
        if refs.count >= 4 {
            throw TonError.custom("Too many references")
        }
        
        refs.append(cell)
        
        return self
    }
    @discardableResult
    public func storeRef(cell: Builder) throws -> Self {
        if refs.count >= 4 {
            throw TonError.custom("Too many references")
        }
        
        refs.append(try cell.endCell())
        
        return self
    }
    
    /**
     Store reference if not null
     - parameter cell: cell or builder to store
     - returns this builder
     */
    @discardableResult
    public func storeMaybeRef(cell: Cell?) throws -> Self {
        if let cell = cell {
            try write(bit: true)
            try storeRef(cell: cell)
        } else {
            try write(bit: false)
        }
        
        return self
    }
    @discardableResult
    public func storeMaybeRef(cell: Builder?) throws -> Self {
        if let cell = cell {
            try write(bit: true)
            try storeRef(cell: cell)
        } else {
            try write(bit: false)
        }
        
        return self
    }
    
    /**
     Store slice it in this builder
     - parameter src: source slice
     */
    @discardableResult
    public func storeSlice(src: Slice) throws -> Self {
        let c = src.clone()
        if c.remainingBits > 0 {
            try write(bits: c.loadBits(c.remainingBits))
        }
        while c.remainingRefs > 0 {
            try storeRef(cell: c.loadRef())
        }
        
        return self
    }
    
    /**
     Store slice in this builder if not null
     - parameter src: source slice
     */
    public func storeMaybeSlice(src: Slice?) throws {
        if let src = src {
            try write(bit: true)
            try storeSlice(src: src)
        } else {
            try write(bit: false)
        }
    }
    
    /**
     Store writer or builder
     - parameter writer: writer or builder to store
     - returns this builder
     */
    @discardableResult
    public func store(_ object: Writable) throws -> Self  {
        try object.writeTo(builder: self)
        return self
    }
    
    /**
     Store writer or builder if not null
     - parameter writer: writer or builder to store
     - returns this builder
     */
    @discardableResult
    public func storeMaybe(_ object: Writable?) throws -> Self {
        if let object = object {
            try write(bit: true)
            try store(object)
        } else {
            try write(bit: false)
        }
        
        return self
    }
    
    @discardableResult
    public func storeDict(_ dict: any CodeableDictionary) throws -> Self {
        try dict.writeTo(builder: self)
        return self
    }
    
    @discardableResult
    public func storeDictRoot(_ dict: any CodeableDictionary) throws -> Self {
        try dict.writeRootTo(builder: self)
        return self
    }
    
    /// Completes cell
    /// TODO: make this non-fallible
    public func endCell() throws -> Cell {
        let bits = BitString(data: _buffer, unchecked:(offset: 0, length: _length))
        return try Cell(bits: bits, refs: refs)
    }
    
    /**
     Convert to cell
     - returns cell
     */
    public func asCell() throws -> Cell {
        return try endCell()
    }
    

    /// Write a single bit: the bit is set for positive values, not set for zero or negative
    @discardableResult
    public func write(bit: Int) throws -> Self {
        try checkCapacity(1)
        
        if bit > 0 {
            _buffer[_length / 8] |= 1 << (7 - (_length % 8))
        }
        
        _length += 1
        return self
    }
    
    /// Writes bit as a boolean (true => 1, false => 0)
    @discardableResult
    public func write(bit: Bool) throws -> Self {
        return try write(bit: bit ? 1 : 0)
    }
    
    /// Writes bits from a bitstring
    @discardableResult
    public func write(bits: BitString) throws -> Self {
        for i in 0..<bits.length {
            try write(bit: bits.at(i))
        }
        return self
    }

    /// Writes bits from a literal sequence of numbers
    @discardableResult
    public func write(bits: Int...) throws -> Self {
        try checkCapacity(bits.count)
        for bit in bits {
            if bit > 0 {
                _buffer[_length / 8] |= 1 << (7 - (_length % 8))
            }
            _length += 1
        }
        return self
    }

    /// Writes bits from a textual string of binary digits
    @discardableResult
    public func write(binaryString: String) throws -> Self {
        for s in binaryString {
            if s != "0" && s != "1" {
                throw TonError.custom("Bitstring must contain only 0s and 1s. Invalid character: \(s)")
            }
            try write(bit: s == "1" ? 1 : 0)
        }
        return self
    }

    /// Writes bytes from the src data.
    @discardableResult
    func write(data: Data) throws -> Self {
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
        return self
    }
    
    /**
     Write uint value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    */
    @discardableResult
    public func write<T>(uint value: T, bits: Int) throws  -> Self where T: BinaryInteger {
        return try write(biguint: BigInt(value), bits: bits)
    }
    
    @discardableResult
    public func write(biguint value: BigInt, bits: Int) throws -> Self {
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
                
                return self
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
                
                return self
            }
        }
        
        // Corner case for zero bits
        if bits == 0 {
            if value != 0 {
                throw TonError.custom("value is not zero for \(bits) bits. Got \(value)")
            } else {
                return self
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
        return self
    }
    
    
    @discardableResult
    func write(int value: any BinaryInteger, bits: Int) throws -> Self {
        return try write(bigint: BigInt(value), bits: bits)
    }
    
    /**
     DEPRECATED API
     Write int value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    */
    func writeInt(_ value: Any, bits: Int) throws {
        if let value = value as? BigInt {
            try write(bigint: value, bits: bits)
        } else if let value = value as? Int {
            try write(bigint: BigInt(value), bits: bits)
        } else if let value = value as? any BinaryInteger {
            try write(bigint: BigInt(value), bits: bits)
        } else {
            throw TonError.custom("Invalid value. Got \(value)")
        }
        
    }
    
    @discardableResult
    func write(bigint value: BigInt, bits: Int) throws -> Self {
        var v = value
        if bits < 0 {
            throw TonError.custom("Invalid bit length. Got \(bits)")
        }
        
        if bits == 0 {
            if v != 0 {
                throw TonError.custom("Value is not zero for \(bits) bits. Got \(v)")
            } else {
                return self
            }
        }
        
        if bits == 1 {
            if v != -1 && v != 0 {
                throw TonError.custom("Value is not zero or -1 for \(bits) bits. Got \(v)")
            } else {
                try write(bit: v == -1)
                return self
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
        return self
    }
    
    /**
     Write coins in var uint format
     - parameter amount: amount to write
    */
    @discardableResult
    func writeCoins(coins: Coins) throws -> Self {
        return try writeVarUint(value: coins.amount, bits: 4)
    }
        
    /**
     Wrtie var uint value, used for serializing coins
    - parameter value: value to write as bigint or number
    - parameter bits: header bits to write size
     TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify actual bounds of the incoming number
    */
    @discardableResult
    func writeVarUint(value: UInt64, bits: Int) throws -> Self {
        return try writeVarUint(value: BigUInt(value), bits: bits)
    }
    @discardableResult
    func writeVarUint(value: BigUInt, bits: Int) throws -> Self {
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
            return self
        }

        // Calculate size
        let sizeBytes = Int(ceil(Double(v.bitWidth) / 8.0))
        let sizeBits = sizeBytes * 8

        // Write size
        try write(uint: sizeBytes, bits: bits)

        // Write number
        try write(uint: v, bits: sizeBits)
        
        return self
    }
    
    /// Converts builder into BitString
    public func bitstring() -> BitString {
        return BitString(data: _buffer, unchecked:(offset: 0, length: _length))
    }
    
    /// Converts to data if the bitstring contains a whole number of bytes.
    /// If the bitstring is not byte-aligned, returns error.
    public func alignedBitstring() throws -> Data {
        if !aligned {
            throw TonError.custom("Builder buffer is not byte-aligned")
        }
        return _buffer.subdata(in: 0..._length / 8)
    }

    private func checkCapacity(_ bits: Int) throws {
        if availableBits < bits || bits < 0 {
            throw TonError.custom("Builder overflow: need to write \(bits), but available \(availableBits)")
        }
    }

}
