import XCTest

final class CellTest: XCTestCase {
    
    func testCell() throws {
        // should construct
        let cell = try Cell()
        XCTAssertEqual(cell.type, CellType.ordinary)
        XCTAssertEqual(cell.bits, BitString(data: .init(), offset: 0, length: 0))
        XCTAssertEqual(cell.refs, [])
    }

}
