import XCTest
import BigInt

final class InternalKeySerializerTest: XCTestCase {
    
    func testInternalKeySerializer() throws {
        // should serialize numbers
        let cs = [0, -1, 1, 123123123, -123123123]
        for c in cs {
            XCTAssertEqual(try deserializeInternalKey(value: try serializeInternalKey(value: c)) as! Int, c)
        }
        
        // should serialize bignumbers
        let cs1 = [0, -1, 1, 123123123, -123123123, BigInt("1231231231231237812683128376123"), BigInt("-1231273612873681263871263871263")];
        for c in cs1 {
            XCTAssertEqual(try deserializeInternalKey(value: try serializeInternalKey(value: c)) as! BigInt, c)
        }
        
        // should serialize addresses
        let cs2 = [testAddress(workchain: 0, seed: "1"), testAddress(workchain: 1, seed: "1"), testAddress(workchain: 0, seed: "2"), testAddress(workchain: 0, seed: "4")]
        for c in cs2 {
            XCTAssertEqual(try deserializeInternalKey(value: try serializeInternalKey(value: c)) as! Address, c)
        }
        
        // should serialize buffers
        let cs3 = [Data(hex: "00")!, Data(hex: "ff")!, Data(hex: "0f")!, Data(hex: "0f000011002233456611")!]
        for c in cs3 {
            XCTAssertEqual(try deserializeInternalKey(value: try serializeInternalKey(value: c)) as! Data, c)
        }
    }
    
}
