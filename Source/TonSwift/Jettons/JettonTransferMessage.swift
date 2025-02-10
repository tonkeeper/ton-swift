//
//  JettonTransferMessage.swift
//  
//
//  Created by Grigory on 11.7.23..
//

import Foundation
import BigInt

public struct JettonTransferMessage {
    public static func internalMessage(jettonAddress: Address,
                                       amount: BigInt,
                                       bounce: Bool,
                                       to: Address,
                                       from: Address,
                                       transferAmount: BigUInt = BigUInt(stringLiteral: "100000000"),
                                       forwardPayload: Cell? = nil,
                                       customPayload: Cell? = nil,
                                       stateInit: StateInit? = nil
                                       ) throws -> MessageRelaxed {
        let forwardAmount = BigUInt(stringLiteral: "1")
        let queryId = UInt64(Date().timeIntervalSince1970)
      
        let jettonTransferData = JettonTransferData(queryId: queryId,
                                                    amount: amount.magnitude,
                                                    toAddress: to,
                                                    responseAddress: from,
                                                    forwardAmount: forwardAmount,
                                                    forwardPayload: forwardPayload,
                                                    customPayload: customPayload)
        
        return MessageRelaxed.internal(
            to: jettonAddress,
            value: transferAmount,
            bounce: bounce,
            stateInit: stateInit,
            body: try Builder().store(jettonTransferData).endCell()
        )
    }
  
  public static func internalMessage(jettonAddress: Address,
                                     amount: BigInt,
                                     bounce: Bool,
                                     to: Address,
                                     from: Address,
                                     transferAmount: BigUInt = BigUInt(stringLiteral: "100000000"),
                                     comment: String? = nil,
                                     customPayload: Cell? = nil,
                                     stateInit: StateInit? = nil
                                     ) throws -> MessageRelaxed {
    var commentCell: Cell?
    if comment != nil && comment != "" {
      commentCell = try Builder().store(int: 0, bits: 32).writeSnakeData(Data(comment!.utf8)).endCell()
    }
    return try internalMessage(
      jettonAddress: jettonAddress,
      amount: amount,
      bounce: bounce,
      to: to,
      from: from,
      transferAmount: transferAmount,
      forwardPayload: commentCell,
      customPayload: customPayload,
      stateInit: stateInit
    )
  }
}
