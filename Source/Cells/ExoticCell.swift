import Foundation

public struct ExoticPruned {
    public var mask: UInt32
    public var pruned: [(depth: UInt32, hash: Data)]
}

func exoticPruned(bits: BitString, refs: [Cell]) throws -> ExoticPruned {
    let reader = BitReader(bits: bits)

    let type = try reader.loadUint(bits: 8)
    if type != 1 {
        throw TonError.custom("Pruned branch cell must have type 1, got \(type)")
    }

    if refs.count != 0 {
        throw TonError.custom("Pruned Branch cell can't has refs, got \(refs.count)");
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
        let level = try reader.loadUint(bits: 8)
        mask = LevelMask(mask: level)
        if mask.level < 1 || mask.level > 3 {
            throw TonError.custom("Pruned Branch cell level must be >= 1 and <= 3, got \(mask.level)/\(mask.value)");
        }

        // Read pruned
        let size = 8 + 8 + (mask.apply(level: mask.level - 1).hashCount * (256 /* Hash */ + 16 /* Depth */))
        if bits.length != size {
            throw TonError.custom("Pruned branch cell must have exactly size bits, got \(bits.length)");
        }
    }

    // Read pruned
    var pruned: [(depth: UInt32, hash: Data)] = []
    var hashes: [Data] = []
    var depths: [UInt32] = []
    for _ in 0..<mask.level {
        let hash = try reader.loadBuffer(bytes: 32)
        let depth = try reader.loadUint(bits: 16)
        
        hashes.append(hash)
        depths.append(depth)
        pruned.append((depth: depth, hash: hash))
    }

    return ExoticPruned(mask: mask.value, pruned: pruned)
}


func resolveExotic(bits: BitString, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let reader = BitReader(bits: bits)
    let type = try reader.preloadUint(bits: 8)
    
    switch type {
    case 1:
        return try resolvePruned(bits: bits, refs: refs)
        
    case 2:
        throw TonError.custom("Library cell must be loaded automatically")
        
    case 3:
        return try resolveMerkleProof(bits: bits, refs: refs)
        
    case 4:
        return try resolveMerkleUpdate(bits: bits, refs: refs)
        
    default:
        throw TonError.custom("Invalid exotic cell type: \(type)")
    }
}

func resolvePruned(bits: BitString, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
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

func resolveMerkleProof(bits: BitString, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let _/*merkleProof*/ = try exoticMerkleProof(bits: bits, refs: refs)
    let depths = [UInt32]()
    let hashes = [Data]()
    let mask = LevelMask(mask: refs[0].level >> 1)
    
    return (CellType.merkleProof, depths, hashes, mask)
}

func resolveMerkleUpdate(bits: BitString, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let _/*merkleUpdate*/ = try exoticMerkleUpdate(bits: bits, refs: refs)
    let depths = [UInt32]()
    let hashes = [Data]()
    let mask = LevelMask(mask: (refs[0].level | refs[1].level) >> 1)
    
    return (CellType.merkleUpdate, depths, hashes, mask)
}

@discardableResult
func exoticMerkleUpdate(bits: BitString, refs: [Cell]) throws -> (proofDepth1: UInt32, proofDepth2: UInt32, proofHash1: Data, proofHash2: Data) {
    let reader = BitReader(bits: bits)

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

    let proofHash1 = try reader.loadBuffer(bytes: 32)
    let proofHash2 = try reader.loadBuffer(bytes: 32)
    let proofDepth1 = try reader.loadUint(bits: 16)
    let proofDepth2 = try reader.loadUint(bits: 16)

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
func exoticMerkleProof(bits: BitString, refs: [Cell]) throws -> (proofDepth: UInt32, proofHash: Data) {
    let reader = BitReader(bits: bits)

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
    let proofHash = try reader.loadBuffer(bytes: 32)
    let proofDepth = try reader.loadUint(bits: 16)
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
