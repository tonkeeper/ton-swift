import Foundation
import BigInt

public struct StakeDepositMessage {
  public static func whalesInternalMessage(queryId: BigUInt,
                                           poolAddress: Address,
                                           amount: BigUInt,
                                           forwardAmount: BigUInt,
                                           bounce: Bool = true) throws -> MessageRelaxed {
    let body = Builder()
    try body.store(uint: OpCodes.WHALES_DEPOSIT, bits: 32)
    try body.store(uint: queryId, bits: 64)
    try body.store(coins: Coins(forwardAmount.magnitude))
    
    return MessageRelaxed.internal(
      to: poolAddress,
      value: amount,
      bounce: bounce,
      body: try body.asCell()
    )
  }
  
  public static func liquidTFInternalMessage(queryId: BigUInt,
                                             poolAddress: Address,
                                             amount: BigUInt,
                                             bounce: Bool = true) throws -> MessageRelaxed {
    let body = Builder()
    try body.store(uint: OpCodes.LIQUID_TF_DEPOSIT, bits: 32)
    try body.store(uint: queryId, bits: 64)
    try body.store(uint: 0x000000000005b7ce, bits: 64)
    
    return MessageRelaxed.internal(
      to: poolAddress,
      value: amount,
      bounce: bounce,
      body: try body.asCell()
    )
  }
  
  public static func tfInternalMessage(queryId: BigUInt,
                                             poolAddress: Address,
                                             amount: BigUInt,
                                             bounce: Bool = true) throws -> MessageRelaxed {
    let body = Builder()
    try body.store(uint: 0, bits: 32)
    try body.writeSnakeData(Data("d".utf8))
    
    return MessageRelaxed.internal(
      to: poolAddress,
      value: amount,
      bounce: bounce,
      body: try body.asCell()
    )
  }
}
