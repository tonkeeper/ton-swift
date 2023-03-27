import BigInt
import Foundation

public struct WalletTransferData {
    public let seqno: UInt64
    public let secretKey: Data
    public let messages: [MessageRelaxed]
    public let sendMode: SendMode
    public let timeout: UInt64?
}

public protocol WalletContract: Contract {
    func createTransfer(args: WalletTransferData) throws -> Cell
}
