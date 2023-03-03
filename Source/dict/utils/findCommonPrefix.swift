import Foundation

func findCommonPrefix(src: [String]) -> String {
    // Corner cases
    if src.isEmpty {
        return ""
    }
    if src.count == 1 {
        return src[0]
    }

    // Searching for prefix
    let sorted = src.sorted()
    var size = 0
    for i in 0..<sorted[0].count {
        let sortedI = sorted[0].index(sorted[0].startIndex, offsetBy: i)
        let sortedLast = sorted[sorted.count - 1].index(sorted[sorted.count - 1].startIndex, offsetBy: i)
        if sorted[0][sortedI] != sorted[sorted.count - 1][sortedLast] {
            break
        }
        
        size += 1
    }
    
    return String(src[0].prefix(size))
}
