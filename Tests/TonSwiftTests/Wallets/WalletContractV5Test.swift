import XCTest
import TweetNacl
import BigInt
@testable import TonSwift

final class WalletContractV5Test: XCTestCase {
    
    private let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    private let secretKey = Data(hex: "34aebb9ea454967f16c407c0f8877763e86212116468169d93a3dcbcafe530c95754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    
    func testR1() throws {
      let contractR1 = WalletV5R1(workchain: 0, publicKey: publicKey, walletId: WalletId(networkGlobalId: -239, workchain: 0))
      
      print(try contractR1.address())
        
        XCTAssertEqual(try contractR1.address(), try Address.parse("UQCRix440npsvDU88REZ8uUJ4jedPEiX_QlCgi954nhZUrBP"))
        XCTAssertEqual(try contractR1.stateInit.data?.toString(), "x{000000007FFFFF888000000000002BAA432F436856F08CC980DDD818CD12F6B5894E25852BF947B1224D9EFCE2912_}")
        XCTAssertEqual(try contractR1.stateInit.code?.toString(), "x{02E4CF3B2F4C6D6A61EA0F2B5447D266785B26AF3637DB2DEEE6BCD1AA826F3412}")
        
        let transferMultiple = try contractR1.createTransfer(args: try argsMultiple())
        let signedDataMultiple = try transferMultiple.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellMultiple = try Cell(data: signedDataMultiple)
        
        XCTAssertEqual(try cellMultiple.toString(), """
                       x{C7E0C94840B0F79FB4A63883F1EB89C1B6D7C28A9FDFFF00614E768FC4445CFA06BA291D85B1C755BFD1C2585EAB9A3FEEEB8AAB3E09BD69940DDCEB2B4FBF04}
                       """)
        
        let transferSingle = try contractR1.createTransfer(args: try argsSingle())
        let signedDataSingle = try transferSingle.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellSingle = try Cell(data: signedDataSingle)
        
        XCTAssertEqual(try cellSingle.toString(), """
                       x{789A0A8331A8901A042E0717201F285612FF24B8E758222EA1EF69EE645C9B6DE7B17DBA9677CA69CFC6BA89783B3AFA8D5FCB933C0CF1A4532BEC5F87BDCE04}
                       """)
    }
    
    private func argsMultiple() throws -> WalletTransferData {
        return try WalletTransferData(
            seqno: 2,
            messages: [
                .internal(
                    to: Address.parse("kQD6oPnzaaAMRW24R8F0_nlSsJQni0cGHntR027eT9_sgtwt"),
                    value: BigUInt(0.1 * 1000000000),
                    textPayload: "Hello world: 1"
                ),
                .internal(
                    to: Address.parse("kQD6oPnzaaAMRW24R8F0_nlSsJQni0cGHntR027eT9_sgtwt"),
                    value: BigUInt(0.1 * 1000000000),
                    textPayload: "Hello world: 2"
                )
            ],
            sendMode: SendMode(payMsgFees: true),
            timeout: 1680179023
        )
    }
    
    private func argsSingle() throws -> WalletTransferData {
        return try WalletTransferData(
            seqno: 2,
            messages: [
                .internal(
                    to: Address.parse("kQD6oPnzaaAMRW24R8F0_nlSsJQni0cGHntR027eT9_sgtwt"),
                    value: BigUInt(1 * 1000000000)
                ),
            ],
            sendMode: SendMode(payMsgFees: true),
            timeout: 1680179023
        )
    }
}
