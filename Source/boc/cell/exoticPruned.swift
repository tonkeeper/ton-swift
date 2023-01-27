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
