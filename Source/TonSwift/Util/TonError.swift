import Foundation

enum TonError: Error {
    case indexOutOfBounds(Int)
    case offsetOutOfBounds(Int)
    case custom(String)
}

extension TonError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .indexOutOfBounds(let index):
            return "Index \(index) is out of bounds"
            
        case .offsetOutOfBounds(let offset):
            return "Offset \(offset) is out of bounds"
        
        case .custom(let text):
            return text
        }
    }
}
