import Foundation
import BigInt

public enum BitsMode {
    case int;
    case uint;
}

extension BigInt {
    public func bitsCount(mode: BitsMode) throws -> Int {
        let v = self
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
                throw TonError.custom("Value is negative. Got \(self)")
            }
            
            return (String(v, radix: 2).count)
        }
    }
}

extension Int {
    public func bitsCount(mode: BitsMode) throws -> Int {
        return try BigInt(self).bitsCount(mode: mode)
    }
}
