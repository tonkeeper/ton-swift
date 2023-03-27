import Foundation
import BigInt

public class Builder {
    public private(set) var bits: BitBuilder
    public private(set) var refs: [Cell]
    
    public init() {
        bits = BitBuilder()
        refs = []
    }
    
    public convenience init(_ bits: BitString) throws {
        self.init()
        try self.bits.write(bits: bits)
    }
    
    private init(unchecked: (bits: BitBuilder, refs: [Cell])) {
        bits = unchecked.bits
        refs = unchecked.refs
    }
    
    /// Clones slice at its current state.
    public func clone() -> Builder {
        return Builder(unchecked: (bits: self.bits.clone(), refs: self.refs))
    }
    
    /// Number of written bits
    public var bitsCount: Int {
        return bits.length
    }
    
    /// Number of references added to this cell
    public var refsCount: Int {
        return refs.count
    }
        
    /// Remaining bits available
    public var availableBits: Int {
        return 1023 - bitsCount
    }
    
    /// Remaining refs available
    public var availableRefs: Int {
        return 4 - refsCount
    }
    
    /// Returns metrics for the currently stored data
    public var metrics: CellMetrics {
        return CellMetrics(bitsCount: bits.length, refsCount: refs.count)
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
        try self.bits.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigUInt, bits: Int) throws -> Self {
        try self.bits.writeInt(value, bits: bits)
        return self
    }
    @discardableResult
    public func storeInt(_ value: BigInt, bits: Int) throws -> Self {
        try self.bits.writeInt(value, bits: bits)
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
        try self.bits.write(uint: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigUInt, bits: Int) throws -> Self {
        try self.bits.write(uint: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeUint(_ value: BigInt, bits: Int) throws -> Self {
        try self.bits.write(uint: value, bits: bits)
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
        try self.bits.writeVarUint(value: value, bits: bits)
        return self
    }
    @discardableResult
    public func storeVarUint(value: BigUInt, bits: Int) throws -> Self {
        try self.bits.writeVarUint(value: value, bits: bits)
        return self
    }
    
    /**
     * Store coins value
     * @param amount amount of coins
     * @returns this builder
     */
    @discardableResult
    public func storeCoins(coins: Coins) throws -> Self {
        try self.bits.writeCoins(coins: coins)
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
            try bits.write(bit: true)
            try storeCoins(coins: coins)
        } else {
            try bits.write(bit: false)
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
            try bits.write(bit: true)
            try storeRef(cell: cell)
        } else {
            try bits.write(bit: false)
        }
        
        return self
    }
    @discardableResult
    public func storeMaybeRef(cell: Builder?) throws -> Self {
        if let cell = cell {
            try bits.write(bit: true)
            try storeRef(cell: cell)
        } else {
            try bits.write(bit: false)
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
            try bits.write(bits: c.bits.loadBits(c.remainingBits))
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
            try bits.write(bit: true)
            try storeSlice(src: src)
        } else {
            try bits.write(bit: false)
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
            try bits.write(bit: true)
            try store(object)
        } else {
            try bits.write(bit: false)
        }
        
        return self
    }
    
    /**
     Store dictionary in this builder
    - parameter dict: dictionary to store
    - returns this builder
    */
    @discardableResult
    func storeDict<K: DictionaryKeyTypes, V>(dict: Dictionary<K, V>?, key: DictionaryKeyCoder? = nil, value: TypeCoder? = nil) throws -> Self {
        if let dict = dict {
            try dict.store(builder: self, key: key, value: value)
        } else {
            try bits.write(bit: 0 != 0)
        }
        
        return self
    }
    
    /**
     Store dictionary in this builder directly
    - parameter dict: dictionary to store
    - returns this builder
    */
    @discardableResult
    func storeDictDirect<K: DictionaryKeyTypes, V>(dict: Dictionary<K, V>, key: DictionaryKeyCoder? = nil, value: TypeCoder? = nil) throws -> Self {
        try dict.storeDirect(builder: self, key: key, value: value)
        return self
    }
    
    /// Completes cell
    /// TODO: make this non-fallible
    public func endCell() throws -> Cell {
        return try Cell(bits: bits.build(), refs: refs)
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
        try storeSlice(src: try builder.endCell().beginParse())
    }
}
