import XCTest
import TweetNacl
import BigInt
@testable import TonSwift

/// Vectors generated with the reference TypeScript implementation from
/// https://docs.ton.org/contracts/standard/wallets/telegram/integrate
/// (`@ton/core@0.63.1`, `@ton/crypto@3.3.0`), same key pair as `WalletContractV5Test`.
final class WalletContractTgTest: XCTestCase {

    private let publicKey = Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!
    private let secretKey = Data(hex: "34aebb9ea454967f16c407c0f8877763e86212116468169d93a3dcbcafe530c95754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!

    func testCodeHashMatchesTrampoline() {
        XCTAssertEqual(WalletTg.code.hash().hexString(), WalletTg.codeHashHex)
    }

    func testStateInitAndAddress() throws {
        let contract = WalletTg(publicKey: publicKey)

        XCTAssertEqual(try contract.address(), try Address.parse("0:1f9ce557e302a4d0e3cf474952e9de37e55d38883ae31eb79b49efbe044f6fb0"))
        XCTAssertEqual(try contract.address().toFriendly(testOnly: false, bounceable: false).toString(), "UQAfnOVX4wKk0OPPR0lS6d435V04iDrjHrebSe--BE9vsMAc")
        XCTAssertEqual(try contract.stateInit.data?.toString(), "x{00000000007FFF7F115754865E86D0ADE1199301BBB0319A25ED6B129C4B0A57F28F62449B3DF9C522}")
        XCTAssertEqual(try contract.stateInit.code?.toString(), "x{FF00209821D7498308B9F240DF8085F833D0ED1E20ED53D9}")

        let testnet = WalletTg(publicKey: publicKey, subwalletId: WalletTg.testnetSubwalletId)
        XCTAssertEqual(try testnet.address(), try Address.parse("0:35cda81ff53eb33b438534e60145effec80b5e668ae4abc86bc9c4e2fc8912e7"))
    }

    func testSingleExternal() throws {
        let transfer = try WalletTg(publicKey: publicKey).createTransfer(args: try args(count: 1), messageType: .ext)
        XCTAssertEqual(transfer.signaturePosition, .front)
        try assertBody(transfer, hash: "ebf44d04cbb08fc311db4e332e5199628694b6066b72eec2a3ca6ee6e46d4f2d",
                       signature: "3b229491537587feb65fb8f1a07304c4d72f20fbd568bea8131825aee55f8ce4db2af5551f157efdbb89db0bb2b15ac4efe6463f88b4b3c992ebebeeafc2980c")
    }

    func testSingleInternal() throws {
        let transfer = try WalletTg(publicKey: publicKey).createTransfer(args: try args(count: 1, ignoreErrors: true), messageType: .int)
        try assertBody(transfer, hash: "7d394e643d56af24b1f34de3e448fbf7b43d57aec022ca739af1fe284ca66d8f",
                       signature: "4d8cf2333da635492f51e3ce5418107578db2d491b20e8570c85cec3820aaa80ac41124206b61f19f851a401b50afcbe528229d0efebe6c4ca14d616d6947c0e")
    }

    func testBatchOfTwoFitsOneChunk() throws {
        let transfer = try WalletTg(publicKey: publicKey).createTransfer(args: try args(count: 2), messageType: .ext)
        try assertBody(transfer, hash: "7f0f57f939c90c9f2d55dbdf7a4aef72c9bf7348cc1791411506c248fe5b1a77",
                       signature: "77ab02d917af6819bc2f0e091b4824cd7df0de0b16498b1fd0986cd9adaea9780e60bdce77fce5f3727e6d60b9779afb893230195e696faa3862e9512863e800")
    }

    func testBatchOfFiveSplitsIntoOneAndFour() throws {
        let transfer = try WalletTg(publicKey: publicKey).createTransfer(args: try args(count: 5), messageType: .ext)
        try assertBody(transfer, hash: "915fd3cd2578fed884c661ca9e2dc6a2cbcf132bffc0ef4d4a56762217428741",
                       signature: "aec1a91e1b8976be0938d29e4282136deb872643cf79bc7f199c9574b67f0147c02c35f5d559e00837c3bc25477d02c8e7009c0dde7892018cea605b325a930e")
    }

    func testBatchOfEightSplitsIntoOneThreeFour() throws {
        let transfer = try WalletTg(publicKey: publicKey).createTransfer(args: try args(count: 8), messageType: .ext)
        try assertBody(transfer, hash: "e6d389ecee7f7f1466d15ec473ce872455b66fa3e267728268def4c7a112a335",
                       signature: "34edf632d3431c2cc369a6ed7893170895c79d77909146db86a5cbb1b37832938b26e01bc92a3a33cb6a46b659f0312aec846a43328b764fb06b5e7045e3cc06")
    }

    func testExternalForcesIgnoreErrorsAndInternalDoesNot() throws {
        let contract = WalletTg(publicKey: publicKey)
        let data = try WalletTransferData(seqno: 2, messages: [message(index: 1)], sendMode: SendMode(payMsgFees: true), timeout: 1680179023)

        XCTAssertEqual(try sendMode(of: contract.createTransfer(args: data, messageType: .ext)), 3)
        XCTAssertEqual(try sendMode(of: contract.createTransfer(args: data, messageType: .int)), 1)
    }

    func testHeaderUsesExplicitTimeoutAndDefaultsToOneMinute() throws {
        let contract = WalletTg(publicKey: publicKey)
        let explicit = try contract.createTransfer(args: try args(count: 1), messageType: .ext)
        try XCTAssertEqual(header(of: explicit).validUntil, 1680179023)

        let now = UInt64(Date().timeIntervalSince1970)
        let implicit = try contract.createTransfer(
            args: WalletTransferData(seqno: 0, messages: [message(index: 1)], sendMode: SendMode(payMsgFees: true), timeout: nil),
            messageType: .ext
        )
        let header = try header(of: implicit)
        XCTAssertEqual(header.opCode, WalletTg.OpCode.sendOneMessageExternal)
        XCTAssertEqual(header.subwalletId, WalletTg.mainnetSubwalletId)
        XCTAssertEqual(header.seqno, 0)
        XCTAssertGreaterThanOrEqual(header.validUntil, now + 60)
        XCTAssertLessThanOrEqual(header.validUntil, now + 61)
    }

    func testRejectsEmptyAndOversizedBatches() throws {
        let contract = WalletTg(publicKey: publicKey)
        XCTAssertThrowsError(try contract.createTransfer(args: try args(count: 0), messageType: .ext))
        XCTAssertThrowsError(try contract.createTransfer(args: try args(count: 256), messageType: .ext))
        XCTAssertNoThrow(try contract.createTransfer(args: try args(count: 255), messageType: .ext))
    }

    // MARK: - Helpers

    private func assertBody(_ transfer: WalletTransfer, hash: String, signature: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let body = try transfer.signingMessage.endCell()
        XCTAssertEqual(body.hash().hexString(), hash, file: file, line: line)
        let signed = try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        XCTAssertEqual(signed.hexString(), signature, file: file, line: line)
    }

    private func header(of transfer: WalletTransfer) throws -> (opCode: UInt32, subwalletId: UInt32, validUntil: UInt64, seqno: UInt64) {
        let slice = try transfer.signingMessage.endCell().beginParse()
        return (
            opCode: UInt32(try slice.loadUint(bits: 32)),
            subwalletId: UInt32(try slice.loadUint(bits: 32)),
            validUntil: try slice.loadUint(bits: 32),
            seqno: try slice.loadUint(bits: 32)
        )
    }

    private func sendMode(of transfer: WalletTransfer) throws -> UInt64 {
        let slice = try transfer.signingMessage.endCell().beginParse()
        try slice.skip(32 * 4)
        return try slice.loadUint(bits: 8)
    }

    private func message(index: Int) throws -> MessageRelaxed {
        try .internal(
            to: Address.parse("kQD6oPnzaaAMRW24R8F0_nlSsJQni0cGHntR027eT9_sgtwt"),
            value: BigUInt(100_000_000),
            textPayload: "Hello world: \(index)"
        )
    }

    private func args(count: Int, ignoreErrors: Bool = false) throws -> WalletTransferData {
        let messages: [MessageRelaxed]
        if count == 1 {
            messages = [
                .internal(
                    to: try Address.parse("kQD6oPnzaaAMRW24R8F0_nlSsJQni0cGHntR027eT9_sgtwt"),
                    value: BigUInt(1_000_000_000)
                ),
            ]
        } else {
            messages = try (0..<count).map { try message(index: $0 + 1) }
        }
        return WalletTransferData(
            seqno: 2,
            messages: messages,
            sendMode: SendMode(payMsgFees: true, ignoreErrors: ignoreErrors),
            timeout: 1680179023
        )
    }
}
