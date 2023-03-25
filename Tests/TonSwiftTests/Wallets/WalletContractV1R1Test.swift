import XCTest
import TweetNacl
@testable import TonSwift

final class WalletContractV1R1Test: XCTestCase {
    
    func testWalletContractV1R1() throws {
        // should has balance and correct address
        let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
        let contract = try WalletContractV1R1(workchain: 0, publicKey: publicKey)
        
        XCTAssertEqual(try contract.address(), try Address.parse("EQCtW_zzk6n82ebaVQFq8P_04wOemYhtwqMd3NuArmPODRvD"))
        XCTAssertEqual(try contract.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contract.stateInit.code?.toString(), "x{FF0020DDA4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED54}")
    }
}
