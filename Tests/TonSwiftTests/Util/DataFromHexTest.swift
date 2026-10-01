import XCTest
@testable import TonSwift

final class DataFromHexTest: XCTestCase {

    func testValidHexDecodes() throws {
        XCTAssertEqual(Data(hex: ""), Data())
        XCTAssertEqual(Data(hex: "00"), Data([0x00]))
        XCTAssertEqual(Data(hex: "abcd"), Data([0xab, 0xcd]))
        XCTAssertEqual(Data(hex: "FF"), Data([0xff])) // case-insensitive
    }

    func testOddLengthHexReturnsNil() {
        // An odd number of hex characters cannot form whole bytes. Previously
        // this silently dropped the trailing nibble (e.g. "abc" -> 0xab),
        // returning a wrong non-nil value from a failable initializer.
        XCTAssertNil(Data(hex: "a"))
        XCTAssertNil(Data(hex: "abc"))
        XCTAssertNil(Data(hex: "12345"))
    }

    func testNonHexReturnsNil() {
        XCTAssertNil(Data(hex: "zz"))
        XCTAssertNil(Data(hex: "0g"))
    }
}
