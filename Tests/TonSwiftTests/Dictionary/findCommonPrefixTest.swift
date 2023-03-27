import XCTest
@testable import TonSwift

final class FindCommonPrefixTest: XCTestCase {
    
    func b(_ s: String) -> BitString {
        return try! BitString(binaryString: s)
    }
    func testFindCommonPrefix() throws {
        // should find common prefix
        XCTAssertEqual(findCommonPrefix(src: [b("0000111"), b("0101111"), b("0001111")]), b("0"))
        XCTAssertEqual(findCommonPrefix(src: [b("0000111"), b("0001111"), b("0000101")]), b("000"))
        XCTAssertEqual(findCommonPrefix(src: [b("0000111"), b("1001111"), b("0000101")]), b(""))
    }
    
}
