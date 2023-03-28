import Foundation
import BigInt


/// `Slice` is a class that allows to read cell data (bits and refs), consuming it along the way.
/// Once you have done reading and want to make sure all the data is consumed, call `endParse()`.
public class Slice {
    
    /// Interface for reading bits
    public private(set) var bits: BitReader
    private var refs: [Cell]
    
    init(cell: Cell) {
        bits = BitReader(bits: cell.bits)
        refs = cell.refs
    }

    /// Unchecked initializer for cloning
    fileprivate init(bits: BitReader, refs: [Cell]) {
        self.bits = bits
        self.refs = refs
    }
        
    /// Remaining unread refs in this slice.
    public var remainingRefs: Int {
        return refs.count
    }
    
    /// Remaining unread bits in this slice.
    public var remainingBits: Int {
        return bits.remaining
    }

    /// Loads type T that implements interface Readable
    public func loadType<T: Readable>() throws -> T {
        return try T.readFrom(slice: self)
    }
    
    /// Preloads type T that implements interface Readable
    public func preloadType<T: Readable>() throws -> T {
        return try T.readFrom(slice: self.clone())
    }
    
    /// Loads optional type T via closure. Function reads one bit that indicates the presence of data. If the bit is set, the closure is called to read T.
    public func loadMaybe<T>(_ closure: (Slice) throws -> T) throws -> T? {
        if try bits.loadBit() {
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
        self.bits = tmpslice.bits;
        self.refs = tmpslice.refs;
        return result;
    }
        
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
        if try bits.loadBit() {
            return try loadRef()
        } else {
            return nil
        }
    }
    
    /// Preloads an optional cell reference.
    public func preloadMaybeRef() throws -> Cell? {
        if try bits.preloadBit() {
            return try preloadRef()
        } else {
            return nil
        }
    }
    
    /// Reads a dictionary from the slice.
    public func loadDict<T>() throws -> T where T: CodeableDictionary {
        return try T.readFrom(slice: self)
    }

    /// Reads the non-empty dictionary root directly from this slice.
    public func loadDictRoot<T>() throws -> T where T: CodeableDictionary {
        return try T.readRootFrom(slice: self)
    }

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
        return Slice(bits: bits.clone(), refs: refs)
    }
    
    /// Returns string representation of the slice as a cell.
    public func toString() throws -> String {
        return try loadRemainder().toString()
    }
}
