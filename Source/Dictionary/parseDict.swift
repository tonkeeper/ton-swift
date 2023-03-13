import Foundation
import BigInt

func readUnaryLength(slice: Slice) throws -> UInt64 {
    var res: UInt64 = 0
    while try slice.loadBit() {
        res += 1
    }
    
    return res
}

func doParse<V>(prefix: String, slice: Slice, n: UInt64, res: inout [BigInt: V], extractor: (Slice) throws -> V) throws {
    // Reading label
    let lb0 = try slice.loadBit() ? 1 : 0
    var prefixLength: UInt64 = 0
    var pp = prefix
    
    if lb0 == 0 {
        // Short label detected
        
        // Read
        prefixLength = try readUnaryLength(slice: slice)
        
        // Read prefix
        for _ in 0..<prefixLength {
            pp += try slice.loadBit() ? "1" : "0"
        }
    } else {
        let lb1 = try slice.loadBit() ? 1 : 0
        if lb1 == 0 {
            // Long label detected
            prefixLength = try slice.loadUint(bits: Int(ceil(log2(Double(n + 1)))))
            for _ in 0..<prefixLength {
                pp += try slice.loadBit() ? "1" : "0"
            }
        } else {
            // Same label detected
            let bit = try slice.loadBit() ? "1" : "0"
            prefixLength = try slice.loadUint(bits: Int(ceil(log2(Double(n + 1)))))
            for _ in 0..<prefixLength {
                pp += bit
            }
        }
    }
    
    if n - prefixLength == 0 {
        res[BigInt(pp, radix: 2)!] = try extractor(slice)
    } else {
        let left = try slice.loadRef()
        let right = try slice.loadRef()
        // NOTE: Left and right branches are implicitly contain prefixes '0' and '1'
        if !left.isExotic {
            try doParse(prefix: pp + "0", slice: left.beginParse(), n: n - prefixLength - 1, res: &res, extractor: extractor)
        }
        if !right.isExotic {
            try doParse(prefix: pp + "1", slice: right.beginParse(), n: n - prefixLength - 1, res: &res, extractor: extractor)
        }
    }
}

func parseDict<V>(sc: Slice?, keySize: UInt64, extractor: @escaping (Slice) throws -> V) throws -> [BigInt: V] {
    var res = [BigInt: V]()
    if let sc = sc {
        try doParse(prefix: "", slice: sc, n: keySize, res: &res, extractor: extractor)
    }
    
    return res
}
