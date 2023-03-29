import Foundation
import BigInt

/// `Slice` is a class that allows to read cell data (bits and refs), consuming it along the way.
/// Once you have done reading and want to make sure all the data is consumed, call `endParse()`.
public class Slice {

    private var bitstring: BitString
    private var offset: Int
    private var refs: [Cell]
    

    
    // MARK: - Initializers
        
    init(cell: Cell) {
        bitstring = cell.bits
        offset = 0
        refs = cell.refs
    }

    /// Allows initializing with bitstring
    public init(bits: BitString) {
        self.bitstring = bits
        self.offset = 0
        self.refs = []
    }
    
    /// Initializes Slice with a byte buffer to read the bits from.
    /// This does not parse bag-of-cells. To parse BoC, see `Cell` API instead.
    public init(data: Data) {
        self.bitstring = BitString(data: data)
        self.offset = 0
        self.refs = []
    }
    
    /// Unchecked initializer for cloning
    private init(bitstring: BitString, offset: Int, refs: [Cell]) {
        self.bitstring = bitstring
        self.offset = offset
        self.refs = refs
    }
    
    
    
    // MARK: - Metrics
    
        
    /// Remaining unread refs in this slice.
    public var remainingRefs: Int {
        return refs.count
    }
    
    /// Remaining unread bits in this slice.
    public var remainingBits: Int {
        return bitstring.length - offset
    }
    
    
    
    
    // MARK: - Slice Lifecycle
    
    
    /// Checks if the cell is fully processed without unread bits or refs.
    public func endParse() throws {
        if remainingBits > 0 || remainingRefs > 0 {
            throw TonError.custom("Slice is not empty")
        }
    }

    /// Converts the remaining data in the slice to a Cell.
    /// This is the same as `asCell`, but reads better when you intend to read all the remaining data as a cell.
    public func loadRemainder() throws -> Cell {
        return try asBuilder().endCell()
    }
    
    /// Converts the remaining data in the slice to a Cell.
    /// This is the same as `loadRemainder`, but reads better when you intend to serialize/inspect the slice.
    public func asCell() throws -> Cell {
        return try asBuilder().endCell()
    }
    
    /// Converts slice to a Builder filled with remaining data in this slice.
    public func asBuilder() throws -> Builder {
        let builder = Builder()
        try builder.storeSlice(src: self)
        return builder
    }
    
    /// Clones slice at its current state.
    public func clone() -> Slice {
        return Slice(bitstring: bitstring, offset: offset, refs: refs)
    }
    
    /// Returns string representation of the slice as a cell.
    public func toString() throws -> String {
        return try loadRemainder().toString()
    }
    
    
    
    
    
    // MARK: - Loading generic types

    /// Loads type T that implements interface Readable
    public func loadType<T: CellCodable>() throws -> T {
        return try T.loadFrom(slice: self)
    }
    
    /// Preloads type T that implements interface Readable
    public func preloadType<T: CellCodable>() throws -> T {
        return try T.loadFrom(slice: self.clone())
    }
    
    /// Loads optional type T via closure. Function reads one bit that indicates the presence of data. If the bit is set, the closure is called to read T.
    public func loadMaybe<T>(_ closure: (Slice) throws -> T) throws -> T? {
        if try loadBit() {
            return try closure(self)
        } else {
            return nil
        }
    }
    
    /// Lets you attempt to read a complex data type.
    /// If parsing succeeded, the slice is advanced.
    /// If parsing failed, the slice remains unchanged.
    public func tryLoad<T>(_ closure: (Slice) throws -> T) throws -> T {
        let tmpslice = self.clone();
        let result = try closure(tmpslice);
        self.bitstring = tmpslice.bitstring;
        self.offset = tmpslice.offset;
        self.refs = tmpslice.refs;
        return result;
    }
    
    
    
    // MARK: - Loading Refs
    
    /// Loads a cell reference.
    public func loadRef() throws -> Cell {
        if refs.isEmpty {
            throw TonError.custom("No more references")
        }
        return refs.removeFirst()
    }
    
    /// Preloads a reference without advancing the cursor.
    public func preloadRef() throws -> Cell {
        if refs.isEmpty {
            throw TonError.custom("No more references")
        }
        return refs.first!
    }
    
    /// Loads an optional cell reference.
    public func loadMaybeRef() throws -> Cell? {
        if try loadBit() {
            return try loadRef()
        } else {
            return nil
        }
    }
    
    /// Preloads an optional cell reference.
    public func preloadMaybeRef() throws -> Cell? {
        if try preloadBit() {
            return try preloadRef()
        } else {
            return nil
        }
    }
    
    
    
    // MARK: - Loading Dictionaries
    
    
    /// Reads a dictionary from the slice.
    public func loadDict<T>() throws -> T where T: CellCodableDictionary {
        return try T.loadFrom(slice: self)
    }

    /// Reads the non-empty dictionary root directly from this slice.
    public func loadDictRoot<T>() throws -> T where T: CellCodableDictionary {
        return try T.readRootFrom(slice: self)
    }

    
    
    
    // MARK: - Loading Bits
    
    
    /// Advances cursor by the specified numbe rof bits.
    public func skip(_ bits: Int) throws {
        if bits < 0 || offset + bits > bitstring.length {
            throw TonError.custom("Index \(offset + bits) is out of bounds")
        }
        offset += bits
    }

    /// Load a single bit.
    public func loadBit() throws -> Bool {
        let r = try bitstring.at(offset)
        offset += 1
        return r
    }
    
    /// Load a single bit as a boolean value.
    public func loadBoolean() throws -> Bool {
        return try loadBit()
    }
    
    /// Loads an optional boolean.
    public func loadMaybeBoolean() throws -> Bool? {
        if try loadBit() {
            return try loadBoolean()
        } else {
            return nil
        }
    }

    /// Preload a single bit without advancing the cursor.
    public func preloadBit() throws -> Bool {
        return try bitstring.at(offset)
    }

    /// Loads the specified number of bits in a `BitString`.
    public func loadBits(_ bits: Int) throws -> BitString {
        let r = try bitstring.substring(offset: offset, length: bits)
        offset += bits
        return r
    }

    /// Preloads the specified number of bits in a `BitString` without advancing the cursor.
    public func preloadBits(_ bits: Int) throws -> BitString {
        return try bitstring.substring(offset: offset, length: bits)
    }

    /// Loads whole number of bytes and returns standard `Data` object.
    public func loadBytes(_ bytes: Int) throws -> Data {
        let buf = try _preloadBuffer(bytes: bytes, offset: offset)
        offset += bytes * 8
        
        return buf
    }

    /// Preloads whole number of bytes and returns standard `Data` object without advancing the cursor.
    public func preloadBytes(_ bytes: Int) throws -> Data {
        return try _preloadBuffer(bytes: bytes, offset: offset)
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
            if try bitstring.at(offset + length - 1) {
                length -= 1
                break
            } else {
                length -= 1
            }
        }
        
        // Read substring
        let substring = try bitstring.substring(offset: offset, length: length)
        offset += bits
        
        return substring
    }

    
    
    
    // MARK: - Loading Integers
    
    
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
        offset += bits
        
        return loaded
    }
    
    /**
     Load int value
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadInt(bits: Int) throws -> Int {
        let loaded = try _preloadInt(bits: bits, offset: offset)
        offset += bits
        
        return Int(loaded)
    }
    
    /**
     Load int value as bigint
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadIntBig(bits: Int) throws -> BigInt {
        let loaded = try _preloadBigInt(bits: bits, offset: offset)
        offset += bits
        
        return loaded
    }

    /**
     Preload uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func preloadUint(bits: Int) throws -> UInt64 {
        return try _preloadUint(bits: bits, offset: offset)
    }

    /**
     Preload uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func preloadUintBig(bits: Int) throws -> BigUInt {
        return try _preloadBigUint(bits: bits, offset: offset)
    }
    
    
    /**
     Load varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
     TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify bounds when reading the result.
    */
    func loadVarUint(bits: Int) throws -> UInt64 {
        let size = Int(try loadUint(bits: bits))
        return try loadUint(bits: size * 8)
    }

    /**
     Load varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
     TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify bounds when reading the result.
    */
    func loadVarUintBig(bits: Int) throws -> BigUInt {
        let size = Int(try loadUint(bits: bits))
        return BigUInt(try loadUintBig(bits: size * 8))
    }

    /**
     Preload varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
     TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify bounds when reading the result.
    */
    func preloadVarUint(bits: Int) throws -> UInt64 {
        let size = Int(try _preloadUint(bits: bits, offset: offset))
        return try _preloadUint(bits: size * 8, offset: offset + bits)
    }

    /**
     Preload varuint value
    - parameter bits: number of bits to read the size
    - returns read value as bigint
     TODO: replace with TL-B compatible definition where we specify upper bound in bytes and verify bounds when reading the result.
    */
    func preloadVarUintBig(bits: Int) throws -> BigUInt {
        let size = Int(try _preloadUint(bits: bits, offset: offset))
        return BigUInt(try _preloadUint(bits: size * 8, offset: offset + bits))
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
        
        let sign = try bitstring.at(offset)
        var res = BigInt(0)
        for i in 0..<bits - 1 {
            if try bitstring.at(offset + 1 + i) {
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
            if try bitstring.at(offset + i) {
                res += 1 << BigUInt(bits - i - 1)
            }
        }
        
        return res
    }
    
    private func _preloadInt(bits: Int, offset: Int) throws -> Int64 {
        guard bits != 0 else { return 0 }
        
        let sign = try bitstring.at(offset)
        var res = Int64(0)
        for i in 0..<bits - 1 {
            if try bitstring.at(offset + 1 + i) {
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
            if try bitstring.at(offset + i) {
                res += 1 << UInt64(bits - i - 1)
            }
        }
        
        return res
    }

    private func _preloadBuffer(bytes: Int, offset: Int) throws -> Data {
        if let fastBuffer = try bitstring.subbuffer(offset: offset, length: bytes * 8) {
            return fastBuffer
        }
        
        var buf = Data(count: bytes)
        for i in 0..<bytes {
            buf[i] = UInt8(try _preloadUint(bits: 8, offset: offset + i * 8))
        }
        
        return buf
    }
}
