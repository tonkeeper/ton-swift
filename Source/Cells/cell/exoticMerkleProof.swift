import Foundation

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
