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
    
    public init(seqno: UInt64,
                secretKey: Data,
                messages: [MessageRelaxed],
                sendMode: SendMode,
                timeout: UInt64?) {
        self.seqno = seqno
        self.secretKey = secretKey
        self.messages = messages
        self.sendMode = sendMode
        self.timeout = timeout
    }
}
