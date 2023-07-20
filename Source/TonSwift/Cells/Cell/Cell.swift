import Foundation

/// Number of bits that fits into a cell
public let BitsPerCell = 1023

/// Number of refs that fits into a cell
public let RefsPerCell = 4

/// TON cell
public struct Cell: Hashable, Equatable, CellCodable {
    
    private let basic: BasicCell
    
    public var type: CellType { basic.type }
    public var bits: Bitstring { basic.bits }
    public var refs: [Cell] { basic.refs }

    public var level: UInt32 { mask.level }
    public var isExotic: Bool { type != .ordinary }
    
    public var metrics: CellMetrics {
        CellMetrics(bitsCount: bits.length, refsCount: refs.count)
    }

    // Precomputed data
    private var _hashes: [Data] = []
    private var _depths: [UInt32] = []
    let mask: LevelMask
    
    /// Empty cell with no bits and no refs.
    public static let empty = Cell()
    
    /// Initializes a new cell with. Exotic cells are parsed and resolved using their contents.
    public init(
        exotic: Bool = false,
        bits: Bitstring = Bitstring.empty,
        refs: [Cell] = []
    ) throws {
        
        if exotic {
            self.basic = try BasicCell.exotic(bits: bits, refs: refs)
        } else {
            if refs.count > RefsPerCell {
                throw TonError.custom("Invalid number of references")
            }
            if bits.length > BitsPerCell {
                throw TonError.custom("Bits overflow: \(bits.length) > \(BitsPerCell)")
            }
            
            self.basic = BasicCell(type: .ordinary, bits: bits, refs: refs)
        }
        let precomputed = try self.basic.precompute()
        self.mask = precomputed.mask
        self._depths = precomputed.depths
        self._hashes = precomputed.hashes
    }
    
    public init() {
        self.basic = BasicCell(type: .ordinary, bits: Bitstring.empty, refs: [])
        self.mask = LevelMask()
    }
    
    /// Initializes a new cell with plain bytestring. This does not parse Bag-of-Cells (BoC), but uses provided data as a bitstring (byte-aligned).
    /// Throws if data contains more than 1023 bits.
    public init(data: Data) throws {
        try self.init(bits: Bitstring(data: data))
    }
    
    /**
     Deserialize cells from BOC
    - parameter src: source buffer
    - returns array of cells
    */
    static func fromBoc(src: Data) throws -> [Cell] {
        try deserializeBoc(src: src)
    }

    /**
     Helper class that deserializes a single cell from BOC in base64
    - parameter src: source string
    */
    static func fromBase64(src: String) throws -> Cell {
        guard let data = Data(base64Encoded: src) else {
            throw NSError()
        }

        let parsed = try Cell.fromBoc(src: data)
        if parsed.count != 1 {
            throw TonError.custom("Deserialized more than one cell")
        }

        return parsed[0]
    }
    
    /**
     Get cell hash
    - parameter level: level
    - returns cell hash
    */
    public func hash(level: Int = 3) -> Data {
        _hashes[min(_hashes.count - 1, level)]
    }
    
    /// Returns the lowest-order hash that represents an actual tree of cells, possibly pruned.
    /// This is the hash of the data being transmitted.
    /// For the hash of the underlying contents see  `hash(level:)` method.
    public func representationHash() -> Data {
        _hashes[0]
    }
    
    
    /**
     Get cell depth
    - parameter level: level
    - returns cell depth
    */
    public func depth(level: Int = 3) -> UInt32 {
        _depths[min(_depths.count - 1, level)]
    }
    
    /// Convert cell to slice so it can be parsed.
    /// Same as `toSlice`.
    public func beginParse(allowExotic: Bool = false) throws -> Slice {
        if isExotic && !allowExotic {
            throw TonError.custom("Exotic cells cannot be parsed")
        }
        
        return Slice(cell: self)
    }
    
    /// Convert cell to slice so it can be parsed.
    /// Same as `beginParse`.
    public func toSlice() throws -> Slice {
        try beginParse()
    }

    /// Convert cell to a builder that has this cell pre-stored. Finalizing this builder yields the same cell.
    public func toBuilder() throws -> Builder {
        try Builder().store(slice: toSlice())
    }
    /**
     Serializes cell to BOC
    - parameter opts: options
    */
    func toBoc(idx: Bool = false, crc32: Bool = true) throws -> Data {
        try serializeBoc(root: self, idx: idx, crc32: crc32)
    }
    
    /**
     Format cell to string
    - parameter indent: indentation
    - returns string representation
    */
    public func toString(indent: String = "") throws -> String {
        var t = "x"
        if isExotic {
            switch type {
            case .merkleProof:
                t = "p"
            case .merkleUpdate:
                t = "u"
            case .prunedBranch:
                t = "p"
            default:
                break
            }
        }
        var s = indent + (isExotic ? t : "x") + "{" + (bits.toString()) + "}"
        for i in refs {
            s += "\n" + (try i.toString(indent: indent + " "))
        }
        
        return s
    }

    // MARK: - Equatable

    /**
     Checks cell to be euqal to another cell
    - parameter other: other cell
    - returns true if cells are equal
    */
    public static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.hash() == rhs.hash()
    }

    // Cell is encoded as a separate ref
    // MARK: - CellCodable
    public func storeTo(builder: Builder) throws {
        try builder.store(ref: self)
    }

    public static func loadFrom(slice: Slice) throws -> Self {
        try slice.loadRef()
    }
}

// TODO: Make this functions not global

func getRepr(bits: Bitstring, refs: [Cell], level: UInt32, type: CellType) throws -> Data {
    // Allocate
    let bitsLen = (bits.length + 7) / 8
    var repr = Data(count: 2 + bitsLen + (2 + 32) * refs.count)

    // Write descriptors
    var reprCursor = 0
    repr[reprCursor] = getRefsDescriptor(refs: refs, level: level, type: type)
    reprCursor += 1
    repr[reprCursor] = getBitsDescriptor(bits: bits)
    reprCursor += 1

    // Write bits
    repr.replaceSubrange(reprCursor..<reprCursor + bitsLen, with: bits.bitsToPaddedBuffer())
    reprCursor += bitsLen

    // Write refs
    for c in refs {
        var childDepth: UInt32
        if type == .merkleProof || type == .merkleUpdate {
            childDepth = c.depth(level: Int(level) + 1)
        } else {
            childDepth = c.depth(level: Int(level))
        }
        repr[reprCursor] = UInt8(floor(Double(childDepth) / 256))
        reprCursor += 1
        repr[reprCursor] = UInt8(childDepth % 256)
        reprCursor += 1
    }
    for c in refs {
        var childHash: Data
        if type == .merkleProof || type == .merkleUpdate {
            childHash = c.hash(level: Int(level) + 1)
        } else {
            childHash = c.hash(level: Int(level))
        }
        
        for i in 0..<32 {
            repr[reprCursor + i] = childHash[i]
        }
        
        reprCursor += 32
    }

    return repr
}


public struct ExoticPruned {
    public var mask: UInt32
    public var pruned: [(depth: UInt32, hash: Data)]
}

func exoticPruned(bits: Bitstring, refs: [Cell]) throws -> ExoticPruned {
    let reader = Slice(bits: bits)

    let type = try reader.loadUint(bits: 8)
    if type != 1 {
        throw TonError.custom("Pruned branch cell must have type 1, got \(type)")
    }

    if refs.count != 0 {
        throw TonError.custom("Pruned Branch cell can't has refs, got \(refs.count)")
    }

    // Resolve cell
    var mask: LevelMask
    if bits.length == 280 {
        // Special case for config proof
        // This test proof is generated in the moment of voting for a slashing
        // it seems that tools generate it incorrectly and therefore doesn't have mask in it
        // so we need to hardcode it equal to 1
        mask = LevelMask(mask: 1)
    } else {
        let level = UInt32(try reader.loadUint(bits: 8))
        mask = LevelMask(mask: level)
        if mask.level < 1 || mask.level > 3 {
            throw TonError.custom("Pruned Branch cell level must be >= 1 and <= 3, got \(mask.level)/\(mask.value)")
        }

        // Read pruned
        let size = 8 + 8 + (mask.apply(level: mask.level - 1).hashCount * (256 /* Hash */ + 16 /* Depth */))
        if bits.length != size {
            throw TonError.custom("Pruned branch cell must have exactly size bits, got \(bits.length)")
        }
    }

    // Read pruned
    var pruned: [(depth: UInt32, hash: Data)] = []
    var hashes: [Data] = []
    var depths: [UInt32] = []
    for _ in 0..<mask.level {
        let hash = try reader.loadBytes(32)
        let depth = UInt32(try reader.loadUint(bits: 16))
        
        hashes.append(hash)
        depths.append(depth)
        pruned.append((depth: depth, hash: hash))
    }

    return ExoticPruned(mask: mask.value, pruned: pruned)
}

func resolvePruned(bits: Bitstring, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let pruned = try exoticPruned(bits: bits, refs: refs)
    var depths = [UInt32]()
    var hashes = [Data]()
    let mask = LevelMask(mask: pruned.mask)
    for i in 0..<pruned.pruned.count {
        depths.append(pruned.pruned[i].depth)
        hashes.append(pruned.pruned[i].hash)
    }
    
    return (CellType.prunedBranch, depths, hashes, mask)
}

func resolveMerkleProof(bits: Bitstring, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let _/*merkleProof*/ = try exoticMerkleProof(bits: bits, refs: refs)
    let depths = [UInt32]()
    let hashes = [Data]()
    let mask = LevelMask(mask: refs[0].level >> 1)
    
    return (CellType.merkleProof, depths, hashes, mask)
}

func resolveMerkleUpdate(bits: Bitstring, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let _/*merkleUpdate*/ = try exoticMerkleUpdate(bits: bits, refs: refs)
    let depths = [UInt32]()
    let hashes = [Data]()
    let mask = LevelMask(mask: (refs[0].level | refs[1].level) >> 1)
    
    return (CellType.merkleUpdate, depths, hashes, mask)
}

@discardableResult
func exoticMerkleUpdate(bits: Bitstring, refs: [Cell]) throws -> (proofDepth1: UInt32, proofDepth2: UInt32, proofHash1: Data, proofHash2: Data) {
    let reader = Slice(bits: bits)

    // type + hash + hash + depth + depth
    let size = 8 + (2 * (256 + 16))

    if bits.length != size {
        throw TonError.custom("Merkle Update cell must have exactly (8 + (2 * (256 + 16))) bits, got \(bits.length)")
    }

    if refs.count != 2 {
        throw TonError.custom("Merkle Update cell must have exactly 2 refs, got \(refs.count)")
    }

    let type = try reader.loadUint(bits: 8)
    if type != 4 {
        throw TonError.custom("Merkle Update cell type must be exactly 4, got \(type)")
    }

    let proofHash1 = try reader.loadBytes(32)
    let proofHash2 = try reader.loadBytes(32)
    let proofDepth1 = UInt32(try reader.loadUint(bits: 16))
    let proofDepth2 = UInt32(try reader.loadUint(bits: 16))

    if proofDepth1 != refs[0].depth(level: 0) {
        throw TonError.custom("Merkle Update cell ref depth must be exactly \(proofDepth1), got \(refs[0].depth(level: 0))")
    }

    if proofHash1 != refs[0].hash(level: 0) {
        throw TonError.custom("Merkle Update cell ref hash must be exactly \(proofHash1.hexString()), got \(refs[0].hash(level: 0).hexString())")
    }

    if proofDepth2 != refs[1].depth(level: 0) {
        throw TonError.custom("Merkle Update cell ref depth must be exactly \(proofDepth2), got \(refs[1].depth(level: 0))")
    }

    if proofHash2 != refs[1].hash(level: 0) {
        throw TonError.custom("Merkle Update cell ref hash must be exactly \(proofHash2.hexString()), got \(refs[1].hash(level: 0).hexString())")
    }

    return (proofDepth1, proofDepth2, proofHash1, proofHash2)
}

@discardableResult
func exoticMerkleProof(bits: Bitstring, refs: [Cell]) throws -> (proofDepth: UInt32, proofHash: Data) {
    let reader = Slice(bits: bits)

    // type + hash + depth
    let size = 8 + 256 + 16

    if bits.length != size {
        throw TonError.custom("Merkle Proof cell must have exactly (8 + 256 + 16) bits, got \(bits.length)")
    }
    if refs.count != 1 {
        throw TonError.custom("Merkle Proof cell must have exactly 1 ref, got \(refs.count)")
    }

    // Check type
    let type = try reader.loadUint(bits: 8)
    if type != 3 {
        throw TonError.custom("Merkle Proof cell must have type 3, got \(type)")
    }

    // Check data
    let proofHash = try reader.loadBytes(32)
    let proofDepth = UInt32(try reader.loadUint(bits: 16))
    let refHash = refs[0].hash(level: 0)
    let refDepth = refs[0].depth(level: 0)

    if proofDepth != refDepth {
        throw TonError.custom("Merkle Proof cell ref depth must be exactly \(proofDepth), got \(refDepth)")
    }

    if proofHash != refHash {
        throw TonError.custom("Merkle Proof cell ref hash must be exactly \(proofHash.hexString()), got \(refHash.hexString())")
    }

    return (proofDepth, proofHash)
}

func countSetBits(_ n: UInt32) -> UInt32 {
    var n = n - ((n >> 1) & 0x55555555)
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    
    return (n + (n >> 4) & 0xF0F0F0F) * 0x1010101 >> 24
}

/// Returns minimum number of bits needed to encode values up to this one.
/// This is the same as TL-B notation `#<= n`. To quote the TVM paper:
///
/// Parametrized type `#<= p` with `p : #` (this notation means “p of type #”, i.e., a natural number)
/// denotes the subtype of the natural numbers type #, consisting of integers 0 . . . p;
/// it is serialized into ⌈log2(p + 1)⌉ bits as an unsigned big-endian integer.
public func bitsForInt(_ n: Int) -> Int {
    Int(ceil(log2(Double(n + 1))))
}
