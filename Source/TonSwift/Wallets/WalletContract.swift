import BigInt
import Foundation

/// All wallets implement a compatible interface for sending messages
public protocol WalletContract: Contract {
    func createTransfer(args: WalletTransferData, messageType: MessageType) throws -> WalletTransfer
  
    var maxMessages: Int { get }
}

/// Message type (external | internal) to sign. Is using in v5 wallet contract
public enum MessageType {
    case int, ext
    
    var opCode: Int32 {
        switch self {
        case .int: return OpCodes.SIGNED_INTERNAL
        case .ext: return OpCodes.SIGNED_EXTERNAL
        }
    }
}

public struct WalletTransferData {
    public let seqno: UInt64
    public let messages: [MessageRelaxed]
    public let sendMode: SendMode
    public let timeout: UInt64?
    
    public init(seqno: UInt64,
                messages: [MessageRelaxed],
                sendMode: SendMode,
                timeout: UInt64?) {
        self.seqno = seqno
        self.messages = messages
        self.sendMode = sendMode
        self.timeout = timeout
    }
}

public enum SignaturePosition {
    case front, tail
}

public struct WalletTransfer {
    public let signingMessage: Builder
    public let signaturePosition: SignaturePosition
    
    public init(signingMessage: Builder, signaturePosition: SignaturePosition) {
        self.signingMessage = signingMessage
        self.signaturePosition = signaturePosition
    }
    
    public func signMessage(signer: WalletTransferSigner) throws -> Data {
        return try signer.signMessage(signingMessage.endCell().hash())
    }
}
