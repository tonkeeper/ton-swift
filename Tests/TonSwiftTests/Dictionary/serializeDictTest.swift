import XCTest
import BigInt
@testable import TonSwift

final class SerializeDictTest: XCTestCase {
    
    func testSerializeDict() throws {
        // should build prefix tree
        
        // From docs
        let map: [BigInt: BigInt] = [
            13: 169,
            17: 289,
            239: 57121
        ]
        
        // Test serialization
        let builder = Builder()
        try serializeDict(src: map, keyLength: 16, serializer: { src, cell in
            try cell.storeUint(src, bits: 16)
        }, to: builder)
        
        let root = try builder.endCell()
        XCTAssertEqual(root.hash().first, 200)
        XCTAssertEqual(root.hash().last, 106)
        XCTAssertEqual(root.depth(), 2)
    }
    
}
