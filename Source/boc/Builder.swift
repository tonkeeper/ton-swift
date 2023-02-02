import Foundation

class Builder {
    private var _bits: BitBuilder
    private var _refs: [Cell]

    init() {
        _bits = BitBuilder()
        _refs = []
    }

    /**
     Bits written so far
    */
    var bits: Int {
        return _bits.length
    }

    /**
     References written so far
    */
    var refs: Int {
        return _refs.count
    }

    /**
     Available bits
    */
    var availableBits: Int {
        return 1023 - bits
    }

    /**
     Available references
    */
    var availableRefs: Int {
        return 4 - refs
    }

    /**
     Write a single bit
    - parameter value: bit to write, true or positive number for 1, false or zero or negative for 0
    - returns this builder
    */
    func storeBit(_ value: Bool) throws -> Self {
        try _bits.writeBit(value: value)
        return self
    }

    /**
     Write bits from BitString
    - parameter src: source bits
    - returns this builder
    */
    func storeBits(_ src: BitString) throws -> Self {
        try _bits.writeBits(src: src)
        return self
    }

    /**
     Store Buffer
    - parameter src: source buffer
    - returns this builder
    */
    func storeBuffer(_ src: Data) throws -> Self {
        try _bits.writeBuffer(src: src)
        return self
    }

    /**
     Store uint value
    - parameter value: value as bigint or number
    - parameter bits: number of bits to write
    - returns this builder
    */
    func storeUint(_ value: UInt32, bits: Int) throws -> Self {
        try _bits.writeUint(value: value, bits: bits)
        return self
    }
    
    /**
     Store reference
    - parameter cell: cell or builder to store
    - returns this builder
    */
    func storeRef(cell: Cell) throws -> Self {
        if _refs.count >= 4 {
            throw TonError.custom("Too many references")
        }

        _refs.append(cell)

        return self
    }
    func storeRef(cell: Builder) throws -> Self {
        if _refs.count >= 4 {
            throw TonError.custom("Too many references")
        }

        _refs.append(try cell.endCell())

        return self
    }
    
    /**
     Complete cell
    - returns cell
    */
    func endCell() throws -> Cell {
        return try Cell(bits: _bits.build(), refs: _refs)
    }
    
    /**
     Convert to cell
    - returns cell
    */
    func asCell() throws -> Cell {
        return try endCell()
    }
}
