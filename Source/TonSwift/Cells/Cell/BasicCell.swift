//
//  BasicCell.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import Foundation

/// Internal basic Cell data: type, bits and refs.
/// This is used for internal computations to produce full-featured `Cell` type with various precomputed data.
struct BasicCell: Hashable {
    let type: CellType
    let bits: Bitstring
    let refs: [Cell]
    
    /// Parse the exotic cell
    static func exotic(bits: Bitstring, refs: [Cell]) throws -> Self {
        let reader = Slice(bits: bits)
        let typeInt = try reader.preloadUint(bits: 8)
        
        let type: CellType
        switch typeInt {
        case 1:
            type = try resolvePruned(bits: bits, refs: refs).type
            
        case 2:
            throw TonError.custom("Library cell must be loaded automatically")
            
        case 3:
            type = try resolveMerkleProof(bits: bits, refs: refs).type
            
        case 4:
            type = try resolveMerkleUpdate(bits: bits, refs: refs).type
            
        default:
            throw TonError.custom("Invalid exotic cell type: \(typeInt)")
        }
        
        return BasicCell(type: type, bits: bits, refs: refs)
    }

    // This function replicates precomputation logic on the cell data
    // https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/vm/cells/DataCell.cpp#L214
    func precompute() throws -> (mask: LevelMask, hashes: [Data], depths: [UInt32]) {
        var levelMask: LevelMask
        var pruned: ExoticPruned? = nil
        
        switch type {
        case .ordinary:
            var mask: UInt32 = 0
            for r in refs {
                mask = mask | r.mask.value
            }
            levelMask = LevelMask(mask: mask)
            
        case .prunedBranch:
            pruned = try exoticPruned(bits: bits, refs: refs)
            levelMask = LevelMask(mask: pruned!.mask)
            
        case .merkleProof:
            try exoticMerkleProof(bits: bits, refs: refs)
            levelMask = LevelMask(mask: refs[0].mask.value >> 1)
            
        case .merkleUpdate:
            try exoticMerkleUpdate(bits: bits, refs: refs)
            levelMask = LevelMask(mask: (refs[0].mask.value | refs[1].mask.value) >> 1)
        }
        
        //
        // Calculate hashes and depths
        // NOTE: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/vm/cells/DataCell.cpp#L214
        //
        
        var depths: [UInt32] = []
        var hashes: [Data] = []
        
        let hashCount = type == .prunedBranch ? 1 : levelMask.hashCount
        let totalHashCount = levelMask.hashCount
        let hashIOffset = totalHashCount - hashCount
        
        var hashI: UInt32 = 0
        for levelI in 0...levelMask.level {
            if !levelMask.isSignificant(level: levelI) {
                continue
            }
            
            if hashI < hashIOffset {
                hashI += 1
                continue
            }
            
            // Bits
            var currentBits: Bitstring
            if hashI == hashIOffset {
                if !(levelI == 0 || type == .prunedBranch) {
                    throw TonError.custom("Invalid")
                }
                currentBits = bits
            } else {
                if !(levelI != 0 && type != .prunedBranch) {
                    throw TonError.custom("Invalid: \(levelI), \(type)")
                }
                currentBits = Bitstring(data: hashes[Int(hashI - hashIOffset) - 1], unchecked: (offset: 0, length: 256))
            }
            
            // Depth
            var currentDepth: UInt32 = 0
            for c in refs {
                var childDepth: UInt32
                if type == .merkleProof || type == .merkleUpdate {
                    childDepth = c.depth(level: Int(levelI) + 1)
                } else {
                    childDepth = c.depth(level: Int(levelI))
                }
                currentDepth = max(currentDepth, childDepth)
            }
            if refs.count > 0 {
                currentDepth += 1
            }
            
            // Hash
            let repr = try getRepr(bits: currentBits, refs: refs, level: levelI, type: type)
            let hash = repr.sha256()
            let destI = hashI - hashIOffset
            depths.insert(currentDepth, at: Int(destI))
            hashes.insert(hash, at: Int(destI))
            
            hashI += 1
        }
        
        // Calculate hash and depth for all levels
        var resolvedHashes: [Data] = []
        var resolvedDepths: [UInt32] = []
        if pruned != nil {
            for i in 0..<4 {
                let hashIndex = levelMask.apply(level: UInt32(i)).hashIndex
                let thisHashIndex = levelMask.hashIndex
                if hashIndex != thisHashIndex {
                    resolvedHashes.append(pruned!.pruned[Int(hashIndex)].hash)
                    resolvedDepths.append(pruned!.pruned[Int(hashIndex)].depth)
                } else {
                    resolvedHashes.append(hashes[0])
                    resolvedDepths.append(depths[0])
                }
            }
        } else {
            for i in 0..<4 {
                let hashIndex = levelMask.apply(level: UInt32(i)).hashIndex
                resolvedHashes.append(hashes[Int(hashIndex)])
                resolvedDepths.append(depths[Int(hashIndex)])
            }
        }
        
        return (levelMask, resolvedHashes, resolvedDepths)
    }
}
