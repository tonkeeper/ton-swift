import Foundation
import BigInt

public struct DNSRenewData: CellCodable {
  public let queryId: UInt64
  
  public func storeTo(builder: Builder) throws {
    try builder.store(uint: OpCodes.CHANGE_DNS_RECORD, bits: 32)
    try builder.store(uint: queryId, bits: 64)
    try builder.store(uint: 0, bits: 256)
  }
  
  public static func loadFrom(slice: Slice) throws -> DNSRenewData {
    try slice.skip(32)
    let queryId = try slice.loadUint(bits: 64)
    try slice.skip(256)
    return DNSRenewData(queryId: queryId)
  }
}
