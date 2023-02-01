import XCTest

final class CellTypeTest: XCTestCase {
    
    func testCellType() throws {
        // should match values in c++ code
        XCTAssertEqual(CellType.ordinary.rawValue, -1)
        XCTAssertEqual(CellType.prunedBranch.rawValue, 1)
        XCTAssertEqual(CellType.merkleProof.rawValue, 3)
        XCTAssertEqual(CellType.merkleUpdate.rawValue, 4)
    }

}
