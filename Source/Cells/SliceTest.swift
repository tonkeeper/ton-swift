import XCTest

final class SliceTest: XCTestCase {
    
    func testCSlice() throws {
        // should read uints from slice
        for _ in 0..<1000 {
            let a = UInt64.random(in: 0..<10000000)
            let b = UInt64.random(in: 0..<10000000)
            let builder = BitBuilder()
            try builder.writeUint(value: a, bits: 48)
            try builder.writeUint(value: b, bits: 48)
            
            let bits = try builder.build()
            let reader = try Cell(bits: bits).beginParse()
            XCTAssertEqual(try reader.preloadUint(bits: 48), a)
            XCTAssertEqual(try reader.loadUint(bits: 48), a)
            XCTAssertEqual(try reader.preloadUint(bits: 48), b)
            XCTAssertEqual(try reader.loadUint(bits: 48), b)
            
            // TODO: - create tests for int, varUint, varInt, coins, address
        }
    }

}
