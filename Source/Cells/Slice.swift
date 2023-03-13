import Foundation
import BigInt

/**
 Slice is a class that allows to read cell data
 */
public class Slice {
    private var reader: BitReader
    private var refs: [Cell]
    
    init(reader: BitReader, refs: [Cell]) {
        self.reader = reader.clone()
        self.refs = refs
    }
    
    /**
     Get remaining bits
    */
    public var remainingBits: Int {
        return reader.remaining
    }
    
    /**
     Get remaining refs
    */
    public var remainingRefs: Int {
        return refs.count
    }
    
    /**
     Skip bits
    - parameter bits
    */
    public func skip(bits: Int) throws -> Slice {
        try reader.skip(bits)
        return self
    }
    
    /// Loads a single bit.
    public func loadBit() throws -> Bool {
        return try reader.loadBit()
    }
    
    /// Preloads a single bit without advancing the cursor.
    public func preloadBit() throws -> Bool {
        return try reader.preloadBit()
    }
    
    public func loadBoolean() throws -> Bool {
        return try loadBit()
    }
    
    /// Loads optional type T via closure. Function reads one bit that indicates the presence of data. If the bit is set, the closure is called to read T.
    public func loadMaybe<T>(_ closure: (Slice) throws -> T) throws -> T? {
        if try loadBit() {
            return try closure(self)
        } else {
            return nil
        }
    }

    /// Loads an optional boolean.
    public func loadMaybeBoolean() throws -> Bool? {
        if try loadBit() {
            return try loadBoolean()
        } else {
            return nil
        }
    }
    
    /// Load the number of bits as a new BitString.
    public func loadBits(bits: Int) throws -> BitString {
        return try reader.loadBits(bits)
    }
    
    /**
     Preload bits as a new BitString
    - parameter bits: number of bits to read
    - returns new BitString
    */
    public func preloadBits(bits: Int) throws -> BitString {
        return try reader.preloadBits(bits)
    }
    
    /**
     Load int
    - parameter bits: number of bits to read
    - returns int value
    */
    public func loadInt(bits: Int) throws -> Int {
        return try reader.loadInt(bits: bits)
    }
    
    /**
     Load int
    - parameter bits: number of bits to read
    - returns int value
    */
    public func loadIntBig(bits: Int) throws -> BigInt {
        return try reader.loadIntBig(bits: bits)
    }
    
    /**
     Load uint
    - parameter bits: number of bits to read
    - returns uint value
    */
    public func loadUint(bits: Int) throws -> UInt32 {
        return try reader.loadUint(bits: bits)
    }
    
    /**
     Load uint
    - parameter bits: number of bits to read
    - returns uint value
    */
    public func loadUintBig(bits: Int) throws -> UInt32 {
        return try reader.loadUintBig(bits: bits)
    }
    
    /**
     Preload uint
    - parameter bits: number of bits to read
    - returns uint value
    */
    public func preloadUint(bits: Int) throws -> UInt32 {
        return try reader.preloadUint(bits: bits)
    }
    
    /**
     Preload uint
    - parameter bits number of bits to read
    - returns uint value
     */
    public func preloadUintBig(bits: Int) throws -> UInt32 {
        return try reader.preloadUintBig(bits: bits)
    }
    
    /**
     Load maybe uint
    - parameter bits number of bits to read
    - returns uint value or null
     */
    public func loadMaybeUint(bits: Int) throws -> UInt32? {
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
    public func loadMaybeUintBig(bits: Int) throws -> UInt32? {
        if try loadBit() {
            return try loadUintBig(bits: bits)
        } else {
            return nil
        }
    }
    
    /**
     Load reference
     - returns: Cell
     */
    public func loadRef() throws -> Cell {
        if refs.isEmpty {
            throw TonError.custom("No more references")
        }
        
        return refs.removeFirst()
    }
    
    /**
     Preload reference
     - returns: Cell
     */
    public func preloadRef() throws -> Cell {
        if refs.isEmpty {
            throw TonError.custom("No more references")
        }
        
        return refs.first!
    }
    
    /**
     Load optional reference
     - returns: Cell or nil
     */
    public func loadMaybeRef() throws -> Cell? {
        if try loadBit() {
            return try loadRef()
        } else {
            return nil
        }
    }
    
    /**
     Preload optional reference
     - returns: Cell or nil
     */
    public func preloadMaybeRef() throws -> Cell? {
        if try preloadBit() {
            return try preloadRef()
        } else {
            return nil
        }
    }
    
    /**
     Load byte buffer
     - parameter bytes: number of bytes to load
     - returns: Data
     */
    public func loadBuffer(bytes: Int) throws -> Data {
        return try reader.loadBuffer(bytes: bytes)
    }
    
    /**
     Preload byte buffer
     - parameter bytes: number of bytes to load
     - returns: Data
     */
    public func preloadBuffer(bytes: Int) throws -> Data {
        return try reader.preloadBuffer(bytes: bytes)
    }
    
    /**
     Load string tail
    */
    public func loadStringTail() throws -> String {
        return try readString(slice: self)
    }
    
    /**
     Load varuint
    - parameter bits: number of bits to read in header
    - returns varuint value
    */
    func loadVarUint(bits: Int) throws -> UInt32 {
        return try reader.loadVarUint(bits: bits)
    }
    
    /**
     Load varuint
    - parameter bits: number of bits to read in header
    - returns varuint value
    */
    func loadVarUintBig(bits: Int) throws -> BigUInt {
        return try reader.loadVarUintBig(bits: bits)
    }
    
    /**
     Preload varuint
    - parameter bits: number of bits to read in header
    - returns varuint value
    */
    func preloadVarUint(bits: Int) throws -> UInt32 {
        return try reader.preloadVarUint(bits: bits)
    }
    
    /**
     Preload varuint
    - parameter bits: number of bits to read in header
    - returns varuint value
    */
    func preloadVarUintBig(bits: Int) throws -> BigUInt {
        return try reader.preloadVarUintBig(bits: bits)
    }
    
    /**
     Load coins
    - returns coins value
    */
    public func loadCoins() throws -> Coins {
        return try reader.loadCoins()
    }
    
    /**
     Preload coins
    - returns coins value
    */
    public func preloadCoins() throws -> Coins {
        return try reader.preloadCoins()
    }
    
    /**
     Load maybe coins
    - returns coins value or null
    */
    public func loadMaybeCoins() throws -> Coins? {
        if try reader.loadBit() {
            return try loadCoins()
        }
        
        return nil
    }
    
    /**
     Load internal Address
    - returns Address
    */
    public func loadAddress() throws -> Address {
        return try reader.loadAddress()
    }
    
    /**
     Load optional internal Address
    - returns Address or null
    */
    public func loadMaybeAddress() throws -> Address? {
        return try reader.loadMaybeAddress()
    }
    
    /**
     * Load external address
     * @returns ExternalAddress
     */
    public func loadExternalAddress() throws -> ExternalAddress {
        return try reader.loadExternalAddress()
    }
    
    /**
     * Load optional external address
     * @returns ExternalAddress or null
     */
    public func loadMaybeExternalAddress() throws -> ExternalAddress? {
        return try reader.loadMaybeExternalAddress()
    }
    
    /**
     Loads dictionary
    - parameter key: key description
    - parameter value: value description
    - returns Dictionary<K, V>
    */
    public func loadDict<K: DictionaryKeyTypes, V>(key: DictionaryKey, value: DictionaryValue) throws -> Dictionary<K, V> {
        return try Dictionary.load(key: key, value: value, sc: self)
    }
    
    /**
     Loads dictionary directly from current slice
    - parameter key: key description
    - parameter value: value description
    - returns Dictionary<K, V>
    */
    public func loadDictDirect<K: DictionaryKeyTypes, V>(key: DictionaryKey, value: DictionaryValue) throws -> Dictionary<K, V> {
        return try Dictionary.loadDirect(key: key, value: value, sc: self)
    }
    
    
    /**
     Checks if slice is empty
    */
    public func endParse() throws {
        if remainingBits > 0 || remainingRefs > 0 {
            throw TonError.custom("Slice is not empty")
        }
    }
    
    /**
     Convert slice to cell
    */
    public func asCell() throws -> Cell {
        let builder = Builder()
        try builder.storeSlice(src: self)
        
        return try builder.endCell()
    }
    
    /**
     Convert slice to builder
     */
    public func asBuilder() throws -> Builder {
        let builder = Builder()
        try builder.storeSlice(src: self)
        
        return builder
    }
    
    /**
     Clone slice
    - returns cloned slice
    */
    public func clone() -> Slice {
        return Slice(reader: reader, refs: refs)
    }
    
    /**
     Print slice as string by converting it to cell
    - returns string
    */
    public func toString() throws -> String {
        return try asCell().toString()
    }
}
