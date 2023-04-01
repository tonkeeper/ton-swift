import BigInt
import Foundation

/// All wallets implement a compatible interface for sending messages
public protocol WalletContract: Contract {
    func createTransfer(args: WalletTransferData) throws -> Cell
}

public struct WalletTransferData {
    public let seqno: UInt64
    public let secretKey: Data
    public let messages: [MessageRelaxed]
    public let sendMode: SendMode
    public let timeout: UInt64?
}
