import Foundation

extension String {
    /// Encodes a String into a Cell
    public func toTonCell() throws -> Cell {
        try Builder().writeSnakeData(Data(utf8)).endCell()
    }
}

