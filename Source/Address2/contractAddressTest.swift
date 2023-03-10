import XCTest

final class СontractAddressTest: XCTestCase {
    
    func testСontractAddress() throws {
        // should resolve address correctly
        
        let stateInit = StateInit(
            code: try Builder().storeUint(UInt32(1), bits: 8).endCell(),
            data: try Builder().storeUint(UInt32(2), bits: 8).endCell()
        )
        let addr = try contractAddress(workchain: 0, stateInit: stateInit)
        XCTAssertEqual(addr, try Address.parse(source: "EQCSY_vTjwGrlvTvkfwhinJ60T2oiwgGn3U7Tpw24kupIhHz"))
    }
    
}
