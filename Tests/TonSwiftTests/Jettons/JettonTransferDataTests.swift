//
//  JettonTransferDataTests.swift
//  
//
//  Created by Grigory on 12.7.23..
//

import XCTest
import BigInt
@testable import TonSwift

final class JettonTransferDataTests: XCTestCase {

    private var transferJettonData: JettonTransferData {
        get throws {
            let queryId: UInt64 = 543
            let amount = BigUInt(stringLiteral: "63546")
            let toAddress = Address.mock(workchain: 0, seed: "toAddressSeed")
            let responseAddress = Address.mock(workchain: 0, seed: "responseAddressSeed")
            let forwardAmount = BigUInt(stringLiteral: "789")
            let comment = "Hello, this is a comment"
            let forwardPayload = try Builder().store(int: 0, bits: 32).writeSnakeData(Data(comment.utf8)).endCell()
            
            
            return JettonTransferData(queryId: queryId,
                                      amount: amount,
                                      toAddress: toAddress,
                                      responseAddress: responseAddress,
                                      forwardAmount: forwardAmount,
                                      forwardPayload: forwardPayload)
        }
    }

    func testJettonTransferDataEncodeAndDecode() throws {
        let builder = Builder()
        let transferJettonDataCell = try builder.store(transferJettonData).endCell()
        let decodedJettonTransferData: JettonTransferData = try Slice(cell: transferJettonDataCell).loadType()
        
        let transferJettonData = try transferJettonData
        
        XCTAssertEqual(transferJettonData.queryId, decodedJettonTransferData.queryId)
        XCTAssertEqual(transferJettonData.amount, decodedJettonTransferData.amount)
        XCTAssertEqual(transferJettonData.toAddress, decodedJettonTransferData.toAddress)
        XCTAssertEqual(transferJettonData.responseAddress, decodedJettonTransferData.responseAddress)
        XCTAssertEqual(transferJettonData.forwardAmount, decodedJettonTransferData.forwardAmount)
        XCTAssertEqual(transferJettonData.forwardPayload, decodedJettonTransferData.forwardPayload)
    }
    
    func testJettonTransferDataEncode() throws {
        let builder = Builder()
        let transferJettonDataCell = try builder.store(transferJettonData).endCell()
        
        XCTAssertEqual(try transferJettonDataCell.toString(),
                       """
                       x{0F8A7EA5000000000000021F2F83A8011740C74E876FBD00C1F39161C9DF68563FC469A730CBF932D464EB819239084F001AAD4BD6DAA342C7D03C496083C01AEC31F1A457B8C993C62823E3713E11FD8184062B}
                        x{0000000048656C6C6F2C2074686973206973206120636F6D6D656E74}
                       """)
    }
}
