import Foundation

func bitsForNumber(src: Int, mode: String) throws -> Int {
    let v = src
    
    // Handle negative values
    if mode == "int" {
        // Corner case for zero or -1 value
        if v == 0 || v == -1 {
            return 1
        }

        let v2 = v > 0 ? v : -v
        return (String(v2, radix: 2).count + 1) // Sign bit
        
    } else if mode == "uint" {
        if v < 0 {
            throw TonError.custom("Value is negative. Got \(src)")
        }
        
        return (String(v, radix: 2).count)
    } else {
        throw TonError.custom("Invalid mode. Got \(mode)")
    }
}
