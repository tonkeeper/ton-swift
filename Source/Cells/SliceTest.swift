import XCTest

final class SliceTest: XCTestCase {
    
    func testSlice() throws {
        // should read uints from slice
        for _ in 0..<1000 {
            let a = UInt64.random(in: 0..<10000000)
            let b = UInt64.random(in: 0..<10000000)
            let builder = BitBuilder()
            try builder.write(uint: a, bits: 48)
            try builder.write(uint: b, bits: 48)
            
            let bits = try builder.build()
            let slice = try Cell(bits: bits).beginParse()
            XCTAssertEqual(try slice.bits.preloadUint(bits: 48), a)
            XCTAssertEqual(try slice.bits.loadUint(bits: 48), a)
            XCTAssertEqual(try slice.bits.preloadUint(bits: 48), b)
            XCTAssertEqual(try slice.bits.loadUint(bits: 48), b)
            
            // TODO: - create tests for int, varUint, varInt, coins, address
        }
    }

}
