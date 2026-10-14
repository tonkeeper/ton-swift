import Foundation

/// WalletTg: the wallet contract used by Telegram's native wallet.
///
/// Every account stores an immutable trampoline code that executes the shared
/// implementation from network config parameter `-123`. The address is derived
/// from the trampoline code and the initial storage, which holds the *anchor*
/// public key; the key that signs requests can be rotated on-chain without
/// changing the address, so `publicKey` here is always the anchor key.
///
/// https://docs.ton.org/contracts/standard/wallets/telegram/overview
public final class WalletTg: WalletContract {
    public static let codeHex = "b5ee9c7241010101001a000030ff00209821d7498308b9f240df8085f833d0ed1e20ed53d969427e39"
    public static let codeHashHex = "9149ae51c1e4689710cebf7830297b16acfbadb363a920a537893e7ffeeca768"

    public static let mainnetSubwalletId: UInt32 = 0x7FFF7F11
    public static let testnetSubwalletId: UInt32 = 0x7FFF7FFD

    public static let code: Cell = try! Cell.fromBoc(src: Data(hex: codeHex)!)[0]

    public enum OpCode {
        public static let sendOneMessageInternal: UInt32 = 0x63896E74
        public static let sendOneMessageExternal: UInt32 = 0x63896E75
        public static let sendBulkMessagesInternal: UInt32 = 0x73896E74
        public static let sendBulkMessagesExternal: UInt32 = 0x73896E75
    }

    public let workchain: Int8
    /// Anchor public key: the key stored in the initial state, not necessarily the current signing key.
    public let publicKey: Data
    public let subwalletId: UInt32

    public let maxMessages: Int = 255

    public init(workchain: Int8 = 0, publicKey: Data, subwalletId: UInt32 = WalletTg.mainnetSubwalletId) {
        self.workchain = workchain
        self.publicKey = publicKey
        self.subwalletId = subwalletId
    }

    public var stateInit: StateInit {
        let data = try! Builder()
            .store(uint: 0, bits: 8)   // storage revision
            .store(uint: 0, bits: 32)  // initial seqno
            .store(uint: subwalletId, bits: 32)
            .store(data: publicKey)
            .endCell()
        return StateInit(code: WalletTg.code, data: data)
    }

    /// Builds the request that follows the 512-bit signature. External requests
    /// must ignore send errors (`+2`), otherwise the contract rejects them after
    /// the sequence number has already been committed.
    public func createTransfer(args: WalletTransferData, messageType: MessageType = .ext) throws -> WalletTransfer {
        guard !args.messages.isEmpty else {
            throw TonError.custom("WalletTg transfer requires at least one message")
        }
        guard args.messages.count <= maxMessages else {
            throw TonError.custom("Maximum number of messages in a single transfer is \(maxMessages)")
        }

        let isSingle = args.messages.count == 1
        let opCode: UInt32
        switch (isSingle, messageType) {
        case (true, .int): opCode = OpCode.sendOneMessageInternal
        case (true, .ext): opCode = OpCode.sendOneMessageExternal
        case (false, .int): opCode = OpCode.sendBulkMessagesInternal
        case (false, .ext): opCode = OpCode.sendBulkMessagesExternal
        }

        var sendMode = args.sendMode.rawValue
        if messageType == .ext {
            sendMode |= SendModeIgnoreErrors
        }

        let defaultTimeout = UInt64(Date().timeIntervalSince1970) + 60
        let signingMessage = try Builder()
            .store(uint: opCode, bits: 32)
            .store(uint: subwalletId, bits: 32)
            .store(uint: args.timeout ?? defaultTimeout, bits: 32)
            .store(uint: args.seqno, bits: 32)

        let cells = try args.messages.map { try Builder().store($0).endCell() }
        if isSingle {
            try signingMessage
                .store(uint: sendMode, bits: 8)
                .store(ref: cells[0])
        } else {
            try signingMessage
                .store(uint: cells.count, bits: 8)
                .storeMaybe(ref: WalletTg.packMessages(cells, sendMode: sendMode))
        }

        return WalletTransfer(signingMessage: signingMessage, signaturePosition: .front)
    }

    /// Tolk `array<MessageToSend>` chunks: each chunk starts with a maybe-reference
    /// to the next chunk and holds up to 3 entries, or up to 4 in the last chunk.
    static func packMessages(_ messages: [Cell], sendMode: UInt8) throws -> Cell? {
        var next: Cell?
        var end = messages.count
        while end > 0 {
            let start = max(0, end - (next == nil ? 4 : 3))
            let chunk = try Builder().storeMaybe(ref: next)
            for message in messages[start..<end] {
                try chunk
                    .store(uint: sendMode, bits: 8)
                    .store(ref: message)
            }
            next = try chunk.endCell()
            end = start
        }
        return next
    }
}
