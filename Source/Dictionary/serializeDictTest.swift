import XCTest
import BigInt

final class SerializeDictTest: XCTestCase {
    
    func int2bits(_ i: Int, bits: Int = 16) -> BitString {
        return try! Builder()
            .storeInt(i, bits: bits)
            .endCell()
            .bits
    }
    
    func testSerializeDict() throws {
        // should build prefix tree
        
        // From docs
        let map: [BitString: BigInt] = [
            int2bits(13): 169,
            int2bits(17): 289,
            int2bits(239): 57121
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
