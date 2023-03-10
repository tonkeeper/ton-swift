import Foundation

public struct Cell: Hashable {
    public static let empty = Cell()
    
    private var _hashes: [Data] = []
    private var _depths: [UInt32] = []
    
    public let type: CellType
    public let bits: BitString
    public let refs: [Cell]
    public let mask: LevelMask
    
    public var level: UInt32 { mask.level }
    public var isExotic: Bool { type != .ordinary }
    
    public init(
        exotic: Bool? = nil,
        bits: BitString? = nil,
        refs: [Cell]? = nil
    ) throws {
        let bits = bits ?? BitString.empty
        let refs = refs ?? []
        
        var hashes: [Data]
        var depths: [UInt32]
        var mask: LevelMask
        var type = CellType.ordinary
        if let exotic = exotic, exotic {
            let resolved = try resolveExotic(bits: bits, refs: refs)
            let wonders = try wonderCalculator(type: resolved.type, bits: bits, refs: refs)
            mask = wonders.mask
            depths = wonders.depths
            hashes = wonders.hashes
            type = resolved.type
        } else {
            if refs.count > 4 {
                throw TonError.custom("Invalid number of references")
            }
            if bits.length > 1023 {
                throw TonError.custom("Bits overflow: \(bits.length) > 1023")
            }
            
            let wonders = try wonderCalculator(type: CellType.ordinary, bits: bits, refs: refs)
            mask = wonders.mask
            depths = wonders.depths
            hashes = wonders.hashes
            type = CellType.ordinary
        }
        
        self.type = type
        self.bits = bits
        self.refs = refs
        self.mask = mask
        self._depths = depths
        self._hashes = hashes
    }
    
    private init() {
        self.type = .ordinary
        self.bits = BitString.empty
        self.refs = []
        self.mask = LevelMask()
    }
    
    /**
     Deserialize cells from BOC
    - parameter src: source buffer
    - returns array of cells
    */
    static func fromBoc(src: Data) throws -> [Cell] {
        return try deserializeBoc(src: src)
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
        return _hashes[min(_hashes.count - 1, level)]
    }
    
    /**
     Get cell depth
    - parameter level: level
    - returns cell depth
    */
    public func depth(level: Int = 3) -> UInt32 {
        return _depths[min(_depths.count - 1, level)]
    }
    
    /**
     Beging cell parsing
    - returns a new slice
    */
    public func beginParse(allowExotic: Bool = false) throws -> Slice {
        if isExotic && !allowExotic {
            throw TonError.custom("Exotic cells cannot be parsed");
        }
        
        return Slice(reader: BitReader(bits: bits), refs: refs)
    }
    
    /**
     Serializes cell to BOC
    - parameter opts: options
    */
    func toBoc(idx: Bool? = nil, crc32: Bool? = nil) throws -> Data {
        let idxValue = idx ?? false
        let crc32Value = crc32 ?? true
        
        return try serializeBoc(root: self, idx: idxValue, crc32: crc32Value)
    }
    
    /**
     Format cell to string
    - parameter indent: indentation
    - returns string representation
    */
    public func toString(indent: String? = nil) throws -> String {
        let id = indent ?? ""
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
        var s = id + (isExotic ? t : "x") + "{" + (try bits.toString()) + "}"
        for i in refs {
            s += "\n" + (try i.toString(indent: id + " "))
        }
        
        return s
    }

}

// MARK: - Equatable
extension Cell: Equatable {
    /**
     Checks cell to be euqal to another cell
    - parameter other: other cell
    - returns true if cells are equal
    */
    public static func == (lhs: Cell, rhs: Cell) -> Bool {
        return lhs.hash() == rhs.hash()
    }
}
