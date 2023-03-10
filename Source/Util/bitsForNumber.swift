import Foundation
import BigInt

enum BitsMode {
    case int;
    case uint;
}

func bitsForNumber(src: BigInt, mode: BitsMode) throws -> Int {
    let v = src
    switch mode {
    case .int:
        // Corner case for zero or -1 value
        if v == 0 || v == -1 {
            return 1
        }

        let v2 = v > 0 ? v : -v
        return (String(v2, radix: 2).count + 1) // Sign bit
    case .uint:
        if v < 0 {
            throw TonError.custom("Value is negative. Got \(src)")
        }
        
        return (String(v, radix: 2).count)
    }
}

func bitsForNumber(src: Int, mode: BitsMode) throws -> Int {
    try bitsForNumber(src: BigInt(src), mode: mode)
}
