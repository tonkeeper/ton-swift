import Foundation

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
    let merkleProof = try exoticMerkleProof(bits: bits, refs: refs)
    var depths = [UInt32]()
    var hashes = [Data]()
    let mask = LevelMask(mask: refs[0].level >> 1)
    
    return (CellType.merkleProof, depths, hashes, mask)
}

func resolveMerkleUpdate(bits: BitString, refs: [Cell]) throws -> (type: CellType, depths: [UInt32], hashes: [Data], mask: LevelMask) {
    let merkleUpdate = try exoticMerkleUpdate(bits: bits, refs: refs)
    var depths = [UInt32]()
    var hashes = [Data]()
    let mask = LevelMask(mask: (refs[0].level | refs[1].level) >> 1)
    
    return (CellType.merkleUpdate, depths, hashes, mask)
}
