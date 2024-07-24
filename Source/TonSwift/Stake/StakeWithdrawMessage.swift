import Foundation
import BigInt

public struct StakeWithdrawMessage {
  public static func whalesInternalMessage(queryId: BigUInt,
                                           poolAddress: Address,
                                           amount: BigUInt,
                                           withdrawFee: BigUInt,
                                           forwardAmount: BigUInt,
                                           bounce: Bool = true) throws -> MessageRelaxed {
    let body = Builder()
    try body.store(uint: OpCodes.WHALES_WITHDRAW, bits: 32)
    try body.store(uint: queryId, bits: 64)
    try body.store(coins: Coins(forwardAmount.magnitude))
    try body.store(coins: Coins(amount.magnitude))
    
    return MessageRelaxed.internal(
      to: poolAddress,
      value: withdrawFee,
      bounce: bounce,
      body: try body.asCell()
    )
  }
  
  public static func liquidTFInternalMessage(queryId: BigUInt,
                                             amount: BigUInt,
                                             withdrawFee: BigUInt,
                                             jettonWalletAddress: Address,
                                             responseAddress: Address,
                                             bounce: Bool = true) throws -> MessageRelaxed {
    let customPayload = Builder()
    try customPayload.store(uint: 1, bits: 1)
    try customPayload.store(uint: 0, bits: 1)
    
    let body = Builder()
    try body.store(uint: OpCodes.LIQUID_TF_BURN, bits: 32)
    try body.store(uint: queryId, bits: 64)
    try body.store(coins: Coins(amount.magnitude))
    try body.store(AnyAddress(responseAddress))
    try body.storeMaybe(ref: customPayload.endCell())
    
    return MessageRelaxed.internal(
      to: jettonWalletAddress,
      value: withdrawFee,
      bounce: bounce,
      body: try body.asCell()
    )
  }
  
  public static func tfInternalMessage(queryId: BigUInt,
                                       poolAddress: Address,
                                       amount: BigUInt,
                                       withdrawFee: BigUInt,
                                       bounce: Bool = true) throws -> MessageRelaxed {
    let body = Builder()
    try body.store(uint: 0, bits: 32)
    try body.writeSnakeData(Data("w".utf8))
    
    return MessageRelaxed.internal(
      to: poolAddress,
      value: withdrawFee,
      bounce: bounce,
      body: try body.asCell()
    )
  }
}
