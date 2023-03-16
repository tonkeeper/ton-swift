import Foundation
import BigInt

public class Builder {
    private var _bits: BitBuilder
    private var _refs: [Cell]
    
    // TBD: public var bits: BitBuilder { get { return self._bits } }
    
    public init() {
        _bits = BitBuilder()
        _refs = []
    }
    
    /// Number of written bits
    public var bits: Int {
        return _bits.length
    }
    
    /// Number of references added to this cell
    public var refs: Int {
        return _refs.count
    }
    
    /// Remaining bits available
    public var availableBits: Int {
        return 1023 - bits
    }
    
    /// Remaining refs available
    public var availableRefs: Int {
        return 4 - refs
    }
    
    /// Write a single bit
    @discardableResult
    public func storeBit(_ value: Bool) throws -> Self {
        try _bits.writeBit(value: value)
        return self
    }
    
    /**
     Write bits from BitString
     - parameter src: source bits
     - returns this builder
     */
    @discardableResult
    public func storeBits(_ src: BitString) throws -> Self {
        try _bits.writeBits(src: src)
        return self
    }
    
    /**
     Store Buffer
     - parameter src: source buffer
     - returns this builder
     */
    @discardableResult
    public func storeBuffer(_ src: Data) throws -> Self {
        try _bits.writeData(src)
        return self
    }
    
    /**
     Store int value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    - returns this builder
    */
    @discardableResult
    public func storeInt(_ value: Int, bits: Int) throws -> Self {
        try _bits.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigUInt, bits: Int) throws -> Self {
        try _bits.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigInt, bits: Int) throws -> Self {
        try _bits.writeInt(value, bits: bits)
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
        try _bits.writeUint(value: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigUInt, bits: Int) throws -> Self {
        try _bits.writeUint(value: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigInt, bits: Int) throws -> Self {
        try _bits.writeUint(value: value, bits: bits)
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
        try _bits.writeVarUint(value: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeVarUint(value: BigUInt, bits: Int) throws -> Self {
        try _bits.writeVarUint(value: value, bits: bits)
        return self
    }
    
    /**
     * Store coins value
     * @param amount amount of coins
     * @returns this builder
     */
    @discardableResult
    public func storeCoins(coins: Coins) throws -> Self {
        try _bits.writeCoins(coins: coins)
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
            try storeBit(true)
            try storeCoins(coins: coins)
        } else {
            try storeBit(false)
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
        if _refs.count >= 4 {
            throw TonError.custom("Too many references")
        }
        
        _refs.append(cell)
        
        return self
    }
    @discardableResult
    public func storeRef(cell: Builder) throws -> Self {
        if _refs.count >= 4 {
            throw TonError.custom("Too many references")
        }
        
        _refs.append(try cell.endCell())
        
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
            try storeBit(true)
            try storeRef(cell: cell)
        } else {
            try storeBit(false)
        }
        
        return self
    }
    @discardableResult
    public func storeMaybeRef(cell: Builder?) throws -> Self {
        if let cell = cell {
            try storeBit(true)
            try storeRef(cell: cell)
        } else {
            try storeBit(false)
        }
        
        return self
    }
    
    /**
     Store slice it in this builder
     - parameter src: source slice
     */
    public func storeSlice(src: Slice) throws {
        let c = src.clone()
        if c.remainingBits > 0 {
            try storeBits(c.bits.loadBits(c.remainingBits))
        }
        while c.remainingRefs > 0 {
            try storeRef(cell: c.loadRef())
        }
    }
    
    /**
     Store slice in this builder if not null
     - parameter src: source slice
     */
    public func storeMaybeSlice(src: Slice?) throws {
        if let src = src {
            try storeBit(true)
            try storeSlice(src: src)
        } else {
            try storeBit(false)
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
            try storeBit(true)
            try store(object)
        } else {
            try storeBit(false)
        }
        
        return self
    }
    
    /**
     Store dictionary in this builder
    - parameter dict: dictionary to store
    - returns this builder
    */
    @discardableResult
    func storeDict<K: DictionaryKeyTypes, V>(dict: Dictionary<K, V>?, key: DictionaryKey? = nil, value: DictionaryValue? = nil) throws -> Self {
        if let dict = dict {
            try dict.store(builder: self, key: key, value: value)
        } else {
            try storeBit(0 != 0)
        }
        
        return self
    }
    
    /**
     Store dictionary in this builder directly
    - parameter dict: dictionary to store
    - returns this builder
    */
    @discardableResult
    func storeDictDirect<K: DictionaryKeyTypes, V>(dict: Dictionary<K, V>, key: DictionaryKey? = nil, value: DictionaryValue? = nil) throws -> Self {
        try dict.storeDirect(builder: self, key: key, value: value)
        return self
    }
    
    /**
     Complete cell
    - returns cell
    */
    public func endCell() throws -> Cell {
        return try Cell(bits: _bits.build(), refs: _refs)
    }
    
    /**
     Convert to cell
    - returns cell
    */
    public func asCell() throws -> Cell {
        return try endCell()
    }
}

// MARK: - Writable
extension Builder: Writable {
    public func writeTo(builder: Builder) throws {
//        try storeSlice(src: try builder.endCell().beginParse())
    }
}
