import Foundation

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
