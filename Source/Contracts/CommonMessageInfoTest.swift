import XCTest

final class CommonMessageInfoTest: XCTestCase {
    
    func testCommonMessageInfo() throws {
        // should serialize external-in messages
        let msg = CommonMessageInfo.externalInInfo(
            info: .init(
                src: try ExternalAddress.mock(seed: "addr-2"),
                dest: Address.mock(workchain: 0, seed: "addr-1"),
                importFee: Coins(amount: 0)
            )
        )
        
        let builder = Builder()
        let cell = try builder.store(CommonMessageInfo.storeCommonMessageInfo(source: msg, builder: builder)).endCell()
        print("!!!cell", try cell.toString())
        let msg2 = try CommonMessageInfo.loadCommonMessageInfo(slice: try cell.beginParse())
        let builder2 = Builder()
        let cell2 = try builder2.store(CommonMessageInfo.storeCommonMessageInfo(source: msg2, builder: builder2)).endCell()
        print("!!!cell2", try cell2.toString())
        XCTAssertEqual(cell, cell2)
    }
}
