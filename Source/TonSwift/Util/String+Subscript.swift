import Foundation

extension String {
    public subscript(_ idx: Int) -> Character {
        self[index(startIndex, offsetBy: idx)]
    }
}
