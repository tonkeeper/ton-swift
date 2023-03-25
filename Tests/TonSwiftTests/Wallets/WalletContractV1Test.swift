import XCTest
import TweetNacl
@testable import TonSwift

final class WalletContractV1Test: XCTestCase {
    
    func testWalletContractV1() throws {
        // should has balance and correct address
        let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
        let contractR1 = try WalletContractV1(workchain: 0, publicKey: publicKey, revision: .r1)
        
        XCTAssertEqual(try contractR1.address(), try Address.parse("EQCtW_zzk6n82ebaVQFq8P_04wOemYhtwqMd3NuArmPODRvD"))
        XCTAssertEqual(try contractR1.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR1.stateInit.code?.toString(), "x{FF0020DDA4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED54}")
        
        let contractR2 = try WalletContractV1(workchain: 0, publicKey: publicKey, revision: .r2)
        
        XCTAssertEqual(try contractR2.address(), try Address.parse("EQATDkvcCA2fFWbSTHMpGCrjkNGqgEywES15ZS11HHY3UuxK"))
        XCTAssertEqual(try contractR2.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR2.stateInit.code?.toString(), "x{FF0020DD2082014C97BA9730ED44D0D70B1FE0A4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED54}")
        
        let contractR3 = try WalletContractV1(workchain: 0, publicKey: publicKey, revision: .r3)
        
        XCTAssertEqual(try contractR3.address(), try Address.parse("EQBRRPBUtgzq5om6O4rtxwPW4hyDxiXYeIko27tvsm97kUw3"))
        XCTAssertEqual(try contractR3.stateInit.data?.toString(), "x{000000005754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contractR3.stateInit.code?.toString(), "x{FF0020DD2082014C97BA218201339CBAB19C71B0ED44D0D31FD70BFFE304E0A4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED54}")
    }
}
