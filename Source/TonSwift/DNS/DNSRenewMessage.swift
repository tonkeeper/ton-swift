import Foundation
import BigInt

public struct DNSRenewMessage {
  public static func internalMessage(nftAddress: Address,
                                     dnsLinkAmount: BigUInt,
                                     stateInit: StateInit?) throws -> MessageRelaxed {
    let queryId = UInt64(Date().timeIntervalSince1970)
    let data = DNSRenewData(queryId: queryId)
    return MessageRelaxed.internal(
      to: nftAddress,
      value: dnsLinkAmount,
      bounce: true,
      body: try Builder().store(
        data
      ).endCell()
    )
  }
}
