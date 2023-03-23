import XCTest
@testable import TonSwift

final class FindCommonPrefixTest: XCTestCase {
    
    func testFindCommonPrefix() throws {
        // should find common prefix
        XCTAssertEqual(findCommonPrefix(src: ["0000111", "0101111", "0001111"]), "0")
        XCTAssertEqual(findCommonPrefix(src: ["0000111", "0001111", "0000101"]), "000")
        XCTAssertEqual(findCommonPrefix(src: ["0000111", "1001111", "0000101"]), "")
    }
    
}
