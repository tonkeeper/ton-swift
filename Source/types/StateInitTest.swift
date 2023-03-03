import XCTest

final class StateInitTest: XCTestCase {

    func testStateInit() throws {
        // shoild serialize to match golden-1
        
        // Serialize
        let boc = try Builder()
            .store(writer: storeStateInit(src:
                    .init(code: try Builder().storeUint(UInt32(1), bits: 8).endCell(),
                          data: try Builder().storeUint(UInt32(2), bits: 8).endCell())
            ))
            .endCell()
            .toBoc(idx: false, crc32: true)
        
        XCTAssertEqual(boc.base64EncodedString(), "te6cckEBAwEACwACATQCAQACAgACAX/38hg=")
    }
}
