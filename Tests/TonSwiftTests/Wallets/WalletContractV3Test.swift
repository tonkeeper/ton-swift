import XCTest
import TweetNacl
@testable import TonSwift

final class WalletContractV3Test: XCTestCase {
    
    private let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    
    func testWalletContractV3() throws {
        try testR1()
        try testR2()
    }
    
    private func testR1() throws {
        let contractR1 = try WalletContractV3(workchain: 0, publicKey: publicKey, revision: .r1)
        
        XCTAssertEqual(try contractR1.address(), try Address.parse("EQBJp7j5N40GXJbAqFSnfTV1Af4ZTyHIMpRbKcudNhWJbbNO"))
        XCTAssertEqual(try contractR1.stateInit.data?.toString(), "x{0000000029A9A3175754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR1.stateInit.code?.toString(), "x{FF0020DD2082014C97BA9730ED44D0D70B1FE0A4F2608308D71820D31FD31FD31FF82313BBF263ED44D0D31FD31FD3FFD15132BAF2A15144BAF2A204F901541055F910F2A3F8009320D74A96D307D402FB00E8D101A4C8CB1FCB1FCBFFC9ED54}")
    }
    
    private func testR2() throws {
        let contractR2 = try WalletContractV3(workchain: 0, publicKey: publicKey, revision: .r2)
        
        XCTAssertEqual(try contractR2.address(), try Address.parse("EQA0D_5WdusaCB-SpnoE6l5TzdBmgOkzTcXrdh0px6g3zJSk"))
        XCTAssertEqual(try contractR2.stateInit.data?.toString(), "x{0000000029A9A3175754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR2.stateInit.code?.toString(), "x{FF0020DD2082014C97BA218201339CBAB19F71B0ED44D0D31FD31F31D70BFFE304E0A4F2608308D71820D31FD31FD31FF82313BBF263ED44D0D31FD31FD3FFD15132BAF2A15144BAF2A204F901541055F910F2A3F8009320D74A96D307D402FB00E8D101A4C8CB1FCB1FCBFFC9ED54}")
    }
}
