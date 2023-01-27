import Foundation

public struct Cell {
    public static let empty = Cell()
    
    private var _hashes: [Data] = []
    private var _depths: [UInt32] = []
    
    public let type: CellType
    public let bits: BitString
    public let refs: [Cell]
    public let mask: LevelMask
    
    public var level: UInt32 { mask.level }
    
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

    
}

