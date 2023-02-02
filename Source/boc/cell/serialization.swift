import Foundation

struct Boc {
    let size: Int
    let offBytes: Int
    let cells: Int
    let roots: UInt32
    let absent: UInt32
    let totalCellSize: Int
    let index: Data?
    let cellData: Data
    let root: [UInt32]
}

func readCell(reader: BitReader, sizeBytes: Int) throws -> (exotic: Bool, bits: BitString, refs: [UInt32]) {
    let d1 = try reader.loadUint(bits: 8)
    let refsCount = d1 % 8
    let exotic = d1 & 8 != 0
    
    let d2 = try reader.loadUint(bits: 8)
    let dataBytesize = Int(ceil(Double(d2) / 2.0))
    let paddingAdded = d2 % 2 != 0
    
    var bits = BitString.empty
    if dataBytesize > 0 {
        if paddingAdded {
            bits = try reader.loadPaddedBits(bits: dataBytesize * 8)
        } else {
            bits = try reader.loadBits(dataBytesize * 8)
        }
    }
    
    var refs: [UInt32] = []
    for _ in 0..<refsCount {
        refs.append(try reader.loadUint(bits: sizeBytes * 8))
    }
    
    return (exotic: exotic, bits: bits, refs: refs)
}

func calcCellSize(cell: Cell, sizeBytes: Int) -> Int {
    return 2 /* D1+D2 */ + Int(ceil(Double(cell.bits.length) / 8.0)) + cell.refs.count * sizeBytes
}

func parseBoc(src: Data) throws -> Boc {
    let reader = BitReader(bits: BitString(data: src, offset: 0, length: src.count * 8))
    let magic = try reader.loadUint(bits: 32)
    if magic == 0x68ff65f3 {
        let size = Int(try reader.loadUint(bits: 8))
        let offBytes = Int(try reader.loadUint(bits: 8))
        let cells = Int(try reader.loadUint(bits: size * 8))
        let roots = try reader.loadUint(bits: size * 8) // Must be 1
        let absent = try reader.loadUint(bits: size * 8)
        let totalCellSize = Int(try reader.loadUint(bits: offBytes * 8))
        let index = try reader.loadBuffer(bytes: cells * offBytes)
        let cellData = try reader.loadBuffer(bytes: totalCellSize)
        
        return Boc(
            size: size,
            offBytes: offBytes,
            cells: cells,
            roots: roots,
            absent: absent,
            totalCellSize: totalCellSize,
            index: index,
            cellData: cellData,
            root: [0])
        
    } else if magic == 0xacc3a728 {
        let size = Int(try reader.loadUint(bits: 8))
        let offBytes = Int(try reader.loadUint(bits: 8))
        let cells = Int(try reader.loadUint(bits: size * 8))
        let roots = try reader.loadUint(bits: size * 8) // Must be 1
        let absent = try reader.loadUint(bits: size * 8)
        let totalCellSize = Int(try reader.loadUint(bits: offBytes * 8))
        let index = try reader.loadBuffer(bytes: cells * offBytes)
        let cellData = try reader.loadBuffer(bytes: totalCellSize)
        let crc32 = try reader.loadBuffer(bytes: 4)
        
        // Swift does not have a built-in crc32c function, you will need to use a library or implement your own
        if crc32c(source: src.subdata(in: 0..<src.count-4)) != crc32 {
            throw TonError.custom("Invalid CRC32C")
        }
        
        return Boc(
            size: size,
            offBytes: offBytes,
            cells: cells,
            roots: roots,
            absent: absent,
            totalCellSize: totalCellSize,
            index: index,
            cellData: cellData,
            root: [0])
        
    } else if magic == 0xb5ee9c72 {
        let hasIdx = try reader.loadUint(bits: 1) == 1
        let hasCrc32c = try reader.loadUint(bits: 1) == 1
        let hasCacheBits = try reader.loadUint(bits: 1) == 1
        let flags = try reader.loadUint(bits: 2) // Must be 0
        let size = Int(try reader.loadUint(bits: 3))
        let offBytes = Int(try reader.loadUint(bits: 8))
        let cells = Int(try reader.loadUint(bits: size * 8))
        let roots = try reader.loadUint(bits: size * 8)
        let absent = try reader.loadUint(bits: size * 8)
        let totalCellSize = Int(try reader.loadUint(bits: offBytes * 8))
        var root: [UInt32] = []
        
        for _ in 0..<roots {
            root.append(try reader.loadUint(bits: size * 8))
        }
        
        var index: Data? = nil
        if hasIdx {
            index = try reader.loadBuffer(bytes: cells * offBytes)
        }
        
        let cellData = try reader.loadBuffer(bytes: totalCellSize)
        if hasCrc32c {
            let crc32 = try reader.loadBuffer(bytes: 4)
            
            if crc32c(source: src.subdata(in: 0..<(src.count - 4))) != crc32 {
                throw TonError.custom("Invalid CRC32C")
            }
        }
        
        return Boc(
            size: size,
            offBytes: offBytes,
            cells: cells,
            roots: roots,
            absent: absent,
            totalCellSize: totalCellSize,
            index: index,
            cellData: cellData,
            root: [0])
        
    } else {
        throw TonError.custom("Invalid magic")
    }
}

func deserializeBoc(src: Data) throws -> [Cell] {
    let boc = try parseBoc(src: src)
    let reader = BitReader(bits: BitString(data: boc.cellData, offset: 0, length: boc.cellData.count * 8))
    
    var cells: [(bits: BitString, refs: [UInt32], exotic: Bool, result: Cell?)] = []
    for _ in 0..<boc.cells {
        let cell = try readCell(reader: reader, sizeBytes: boc.size)
        cells.append((cell.bits, cell.refs, cell.exotic, nil))
    }
    
    for i in stride(from: cells.count - 1, through: 0, by: -1) {
        if cells[i].result != nil {
            throw TonError.custom("Impossible")
        }
        
        var refs: [Cell] = []
        for r in cells[i].refs {
            if let result = cells[Int(r)].result {
                refs.append(result)
            } else {
                throw TonError.custom("Invalid BOC file")
            }
        }
        
        cells[i].result = try Cell(exotic: cells[i].exotic, bits: cells[i].bits, refs: refs)
    }

    var roots: [Cell] = []
    for i in 0..<boc.root.count {
        roots.append(cells[Int(boc.root[i])].result!)
    }

    return roots
}

func writeCellToBuilder(cell: Cell, refs: [UInt32], sizeBytes: Int, to: BitBuilder) throws -> BitBuilder {
    let d1 = getRefsDescriptor(refs: cell.refs, level: cell.level, type: cell.type)
    let d2 = getBitsDescriptor(bits: cell.bits)
    
    try to.writeUint(value: UInt32(d1), bits: 8)
    try to.writeUint(value: UInt32(d2), bits: 8)
    try to.writeBuffer(src: bitsToPaddedBuffer(bits: cell.bits))
    
    for r in refs {
        try to.writeUint(value: r, bits: sizeBytes * 8)
    }
    
    return to
}

func serializeBoc(root: Cell, idx: Bool, crc32: Bool) throws -> Data {
    let allCells = try topologicalSort(src: root)
    
    let cellsNum = allCells.count
    let hasIdx = idx
    let hasCrc32c = crc32
    let hasCacheBits = false
    let flags: UInt32 = 0
    let sizeBytes = max(Int(ceil(Double(try bitsForNumber(src: cellsNum, mode: "uint")) / 8.0)), 1)
    var totalCellSize: Int = 0
    var index: [Int] = []
    
    for c in allCells {
        let sz = calcCellSize(cell: c.cell, sizeBytes: sizeBytes)
        index.append(totalCellSize)
        totalCellSize += sz
    }
    
    let offsetBytes = max(Int(ceil(Double(try bitsForNumber(src: totalCellSize, mode: "uint")) / 8.0)), 1)
    let hasIdxFactor = hasIdx ? (cellsNum * offsetBytes) : 0
    let hasCrc32cFactor = hasCrc32c ? 4 : 0
    let totalSize = (
        4 + // magic
        1 + // flags and s_bytes
        1 + // offset_bytes
        3 * sizeBytes + // cells_num, roots, complete
        offsetBytes + // full_size
        1 * sizeBytes + // root_idx
        hasIdxFactor +
        totalCellSize +
        hasCrc32cFactor
    ) * 8

    // Serialize
    var builder = BitBuilder(size: totalSize)
    try builder.writeUint(value: UInt32(0xb5ee9c72), bits: 32) // Magic
    try builder.writeBit(value: hasIdx) // Has index
    try builder.writeBit(value: hasCrc32c) // Has crc32c
    try builder.writeBit(value: hasCacheBits) // Has cache bits
    try builder.writeUint(value: flags, bits: 2) // Flags
    try builder.writeUint(value: UInt32(sizeBytes), bits: 3) // Size bytes
    try builder.writeUint(value: UInt32(offsetBytes), bits: 8) // Offset bytes
    try builder.writeUint(value: UInt32(cellsNum), bits: sizeBytes * 8) // Cells num
    try builder.writeUint(value: UInt32(1), bits: sizeBytes * 8) // Roots num
    try builder.writeUint(value: UInt32(0), bits: sizeBytes * 8) // Absent num
    try builder.writeUint(value: UInt32(totalCellSize), bits: offsetBytes * 8) // Total cell size
    try builder.writeUint(value: UInt32(0), bits: sizeBytes * 8) // Root id == 0

    if hasIdx {
        for i in 0 ..< cellsNum {
            try builder.writeUint(value: UInt32(index[i]), bits: offsetBytes * 8)
        }
    }

    for i in 0 ..< cellsNum {
        builder = try writeCellToBuilder(
            cell: allCells[i].cell,
            refs: allCells[i].refs,
            sizeBytes: sizeBytes,
            to: builder
        )
    }

    if hasCrc32c {
        let crc32 = crc32c(source: try builder.buffer())
        try builder.writeBuffer(src: crc32)
    }

    let res = try builder.buffer()
    if res.count != totalSize / 8 {
        throw TonError.custom("Internal error")
    }
    
    return res
}
