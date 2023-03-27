import XCTest
import TweetNacl
@testable import TonSwift

final class WalletContractV2Test: XCTestCase {
    
    private let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    
    func testWalletContractV2() throws {
        try testR1()
        try testR2()
    }
    
    private func testR1() throws {
        let contractR1 = try WalletContractV2(workchain: 0, publicKey: publicKey, revision: .r1)
        
        XCTAssertEqual(try contractR1.address(), try Address.parse("EQD3ES67JiTYq5y2eE1-fivl5kANn-gKDDjvpbxNCQWPzs4D"))
        XCTAssertEqual(try contractR1.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR1.stateInit.code?.toString(), "x{FF0020DD2082014C97BA9730ED44D0D70B1FE0A4F2608308D71820D31FD31F01F823BBF263ED44D0D31FD3FFD15131BAF2A103F901541042F910F2A2F800029320D74A96D307D402FB00E8D1A4C8CB1FCBFFC9ED54}")
    }
    
    private func testR2() throws {
        let contractR2 = try WalletContractV2(workchain: 0, publicKey: publicKey, revision: .r2)
        
        XCTAssertEqual(try contractR2.address(), try Address.parse("EQAkAcNLtzCHudScK9Hsk9I_7SrunBWf_9VrA2xJmGebwEsl"))
        XCTAssertEqual(try contractR2.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR2.stateInit.code?.toString(), "x{FF0020DD2082014C97BA218201339CBAB19C71B0ED44D0D31FD70BFFE304E0A4F2608308D71820D31FD31F01F823BBF263ED44D0D31FD3FFD15131BAF2A103F901541042F910F2A2F800029320D74A96D307D402FB00E8D1A4C8CB1FCBFFC9ED54}")
    }
}
