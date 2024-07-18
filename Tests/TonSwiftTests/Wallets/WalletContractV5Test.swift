import XCTest
import TweetNacl
import BigInt
@testable import TonSwift

final class WalletContractV5Test: XCTestCase {
    
    private let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    private let secretKey = Data(hex: "34aebb9ea454967f16c407c0f8877763e86212116468169d93a3dcbcafe530c95754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    
    func testBeta() throws {
        let contractBeta = WalletV5Beta(workchain: 0, publicKey: publicKey, walletId: WalletIdBeta(networkGlobalId: -239, workchain: 0))
        
        XCTAssertEqual(try contractBeta.address(), try Address.parse("UQCRix440npsvDU88REZ8uUJ4jedPEiX_QlCgi954nhZUrBP"))
        XCTAssertEqual(try contractBeta.stateInit.data?.toString(), "x{000000007FFFFF888000000000002BAA432F436856F08CC980DDD818CD12F6B5894E25852BF947B1224D9EFCE2912_}")
        XCTAssertEqual(try contractBeta.stateInit.code?.toString(), "x{02E4CF3B2F4C6D6A61EA0F2B5447D266785B26AF3637DB2DEEE6BCD1AA826F3412}")
        
        let transferMultiple = try contractBeta.createTransfer(args: try argsMultiple())
        let signedDataMultiple = try transferMultiple.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellMultiple = try Cell(data: signedDataMultiple)
        
        XCTAssertEqual(try cellMultiple.toString(), """
                       x{C7E0C94840B0F79FB4A63883F1EB89C1B6D7C28A9FDFFF00614E768FC4445CFA06BA291D85B1C755BFD1C2585EAB9A3FEEEB8AAB3E09BD69940DDCEB2B4FBF04}
                       """)
        
        let transferSingle = try contractBeta.createTransfer(args: try argsSingle())
        let signedDataSingle = try transferSingle.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellSingle = try Cell(data: signedDataSingle)
        
        XCTAssertEqual(try cellSingle.toString(), """
                       x{789A0A8331A8901A042E0717201F285612FF24B8E758222EA1EF69EE645C9B6DE7B17DBA9677CA69CFC6BA89783B3AFA8D5FCB933C0CF1A4532BEC5F87BDCE04}
                       """)
    }
    
    func testR1() throws {
        let contractR1 = WalletV5R1(workchain: 0, publicKey: publicKey, walletId: WalletId(networkGlobalId: -239, workchain: 0))
        
        XCTAssertEqual(try contractR1.address(), try Address.parse("UQBiUbwjoB56b7CYtoiPnY5vPh2Fwjva6jEPBhqnttjQKpce"))
        XCTAssertEqual(try contractR1.stateInit.data?.toString(), "x{800000003FFFFF88ABAA432F436856F08CC980DDD818CD12F6B5894E25852BF947B1224D9EFCE2912_}")
        XCTAssertEqual(try contractR1.stateInit.code?.toString(), "x{FF00F4A413F4BCF2C80B}\n x{2_}\n  x{4}\n   x{D020D749C120915B8F6320D70B1F2082106578746EBD21821073696E74BDB0925F03E082106578746EBA8EB48020D72101D074D721FA4030FA44F828FA443058BD915BE0ED44D0810141D721F4058307F40E6FA1319130E18040D721707FDB3CE03120D749810280B99130E070E2}\n    x{EDA2EDFB02F404216E926C218E4C0221D73930709421C700B38E2D01D72820761E436C20D749C008F2E09320D74AC002F2E09320D71D06C712C2005230B0F2D089D74CD7393001A4E86C128407BBF2E093D74AC000F2E093ED55E2D20001C000915BE0EBD72C08142091709601D72C081C12E25210B1E30F20D74A}\n     x{01FA4001FA44F828FA443058BAF2E091ED44D0810141D718F405049D7FC8CA0040048307F453F2E08B8E14038307F45BF2E08C22D70A00216E01B3B0F2D090E2C85003CF1612F400C9ED54}\n     x{30D72C08248E2D21F2E092D200ED44D0D2005113BAF2D08F54503091319C01810140D721D70A00F2E08EE2C8CA0058CF16C9ED5493F2C08DE2}\n     x{935BDB31E1D74CD0}\n    x{8EF0EDA2EDFB218308D722028308D723208020D721D31FD31FD31FED44D0D200D31F20D31FD3FFD70A000AF90140CCF9109A28945F0ADB31E1F2C087DF02B35007B0F2D0845125BAF2E0855036BAF2E086F823BBF2D0882292F800DE01A47FC8CA00CB1F01CF16C9ED542092F80FDE70DB3CD8}\n     x{EDA2EDFB02F404216E926C218E4C0221D73930709421C700B38E2D01D72820761E436C20D749C008F2E09320D74AC002F2E09320D71D06C712C2005230B0F2D089D74CD7393001A4E86C128407BBF2E093D74AC000F2E093ED55E2D20001C000915BE0EBD72C08142091709601D72C081C12E25210B1E30F20D74A}\n      x{01FA4001FA44F828FA443058BAF2E091ED44D0810141D718F405049D7FC8CA0040048307F453F2E08B8E14038307F45BF2E08C22D70A00216E01B3B0F2D090E2C85003CF1612F400C9ED54}\n      x{30D72C08248E2D21F2E092D200ED44D0D2005113BAF2D08F54503091319C01810140D721D70A00F2E08EE2C8CA0058CF16C9ED5493F2C08DE2}\n      x{935BDB31E1D74CD0}\n   x{2_}\n    x{2_}\n     x{6E_}\n      x{ADCE76A2684020EB90EB85FFC_}\n      x{AF1DF6A2684010EB90EB858FC_}\n     x{4}\n      x{B325FB51341C75C875C2C7E_}\n      x{B262FB513435C2802_}\n    x{BE5F0F6A2684080A0EB90FA02C_}\n  x{F2}\n   x{20D70B1F82107369676EBAF2E08A7F}\n    x{8EF0EDA2EDFB218308D722028308D723208020D721D31FD31FD31FED44D0D200D31F20D31FD3FFD70A000AF90140CCF9109A28945F0ADB31E1F2C087DF02B35007B0F2D0845125BAF2E0855036BAF2E086F823BBF2D0882292F800DE01A47FC8CA00CB1F01CF16C9ED542092F80FDE70DB3CD8}\n     x{EDA2EDFB02F404216E926C218E4C0221D73930709421C700B38E2D01D72820761E436C20D749C008F2E09320D74AC002F2E09320D71D06C712C2005230B0F2D089D74CD7393001A4E86C128407BBF2E093D74AC000F2E093ED55E2D20001C000915BE0EBD72C08142091709601D72C081C12E25210B1E30F20D74A}\n      x{01FA4001FA44F828FA443058BAF2E091ED44D0810141D718F405049D7FC8CA0040048307F453F2E08B8E14038307F45BF2E08C22D70A00216E01B3B0F2D090E2C85003CF1612F400C9ED54}\n      x{30D72C08248E2D21F2E092D200ED44D0D2005113BAF2D08F54503091319C01810140D721D70A00F2E08EE2C8CA0058CF16C9ED5493F2C08DE2}\n      x{935BDB31E1D74CD0}")
        
        let transferMultiple = try contractR1.createTransfer(args: try argsMultiple())
        let signedDataMultiple = try transferMultiple.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellMultiple = try Cell(data: signedDataMultiple)
        
        XCTAssertEqual(try cellMultiple.toString(), """
                     x{7465AD4E852C611ED9845440DBA85623B8CFEE783149903E61113D4D4777F87B9493977B3687BAEC37F835CCB75DCAF74E49617C01D4260BA86B893BFBBBCF0A}
                     """)
        
        let transferSingle = try contractR1.createTransfer(args: try argsSingle())
        let signedDataSingle = try transferSingle.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        let cellSingle = try Cell(data: signedDataSingle)
        
        XCTAssertEqual(try cellSingle.toString(), """
                     x{B2E716ACD0CDDD51437EE4C570971D211601BECA387E57E5678113D61B757CAAA47D3BD246567CF31A10D5940A1D736F94860696FCA6C16F44AA487DE29AE102}
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
