import Foundation
import BigInt

public struct DNSLinkData: CellCodable {
  public let queryId: UInt64
  public let linkAddress: Address?
  
  public func storeTo(builder: Builder) throws {
    try builder.store(uint: OpCodes.CHANGE_DNS_RECORD, bits: 32)
    try builder.store(uint: queryId, bits: 64)
    try builder.store(
      biguint: BigUInt("e8d44050873dba865aa7c170ab4cce64d90839a34dcfd6cf71d14e0205443b1b", radix: 16) ?? 0,
      bits: 256
    )
    if let linkAddress {
      try builder.storeMaybe(ref: try Builder()
        .store(uint: 0x9fd3, bits: 16)
        .store(AnyAddress(linkAddress))
        .store(uint: 0, bits: 8))
    }
  }
  
  public static func loadFrom(slice: Slice) throws -> DNSLinkData {
    try slice.skip(32)
    let queryId = try slice.loadUint(bits: 64)
    try slice.skip(256)
    var address: Address?
    if let ref = try slice.loadMaybeRef() {
      let slice = try ref.toSlice()
      try slice.skip(16)
      address = try slice.loadType()
    }
    return DNSLinkData(queryId: queryId, linkAddress: address)
  }
}
