import Foundation

public extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            
            i = j
        }
        
        self = data
    }

    func subdata(in range: ClosedRange<Index>) -> Data {
        subdata(in: range.lowerBound ..< range.upperBound)
    }

    func hexString() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
