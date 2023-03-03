import Foundation

extension Int {
    var isSafe: Bool {
        self >= Int.min && self <= Int.max
    }
}
