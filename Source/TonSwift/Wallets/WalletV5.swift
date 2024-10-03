import Foundation
import BigInt

public struct WalletId {
    public let walletVersion: Int8 = 0
    public let subwalletNumber: Int32
    public let networkGlobalId: Int32
    public let workchain: Int8
    
    public init(networkGlobalId: Int32, workchain: Int8 = 0, subwalletNumber: Int32 = 0) {
        self.networkGlobalId = networkGlobalId
        self.workchain = workchain
        self.subwalletNumber = subwalletNumber
    }
}

public class WalletV5R1: WalletV5 {
    public init(seqno: Int64 = 0,
                workchain: Int8 = 0,
                publicKey: Data,
                walletId: WalletId,
                plugins: Set<Address> = []
    ) {
      
      // https://github.com/ton-blockchain/wallet-contract-v5/blob/4fab977f4fae3a37c1aac216ed2b7e611a9bc2af/build/wallet_v5.compiled.json
        let code = try! Cell.fromBase64(src: "te6cckECFAEAAoEAART/APSkE/S88sgLAQIBIAINAgFIAwQC3NAg10nBIJFbj2Mg1wsfIIIQZXh0br0hghBzaW50vbCSXwPgghBleHRuuo60gCDXIQHQdNch+kAw+kT4KPpEMFi9kVvg7UTQgQFB1yH0BYMH9A5voTGRMOGAQNchcH/bPOAxINdJgQKAuZEw4HDiEA8CASAFDAIBIAYJAgFuBwgAGa3OdqJoQCDrkOuF/8AAGa8d9qJoQBDrkOuFj8ACAUgKCwAXsyX7UTQcdch1wsfgABGyYvtRNDXCgCAAGb5fD2omhAgKDrkPoCwBAvIOAR4g1wsfghBzaWduuvLgin8PAeaO8O2i7fshgwjXIgKDCNcjIIAg1yHTH9Mf0x/tRNDSANMfINMf0//XCgAK+QFAzPkQmiiUXwrbMeHywIffArNQB7Dy0IRRJbry4IVQNrry4Ib4I7vy0IgikvgA3gGkf8jKAMsfAc8Wye1UIJL4D95w2zzYEAP27aLt+wL0BCFukmwhjkwCIdc5MHCUIccAs44tAdcoIHYeQ2wg10nACPLgkyDXSsAC8uCTINcdBscSwgBSMLDy0InXTNc5MAGk6GwShAe78uCT10rAAPLgk+1V4tIAAcAAkVvg69csCBQgkXCWAdcsCBwS4lIQseMPINdKERITAJYB+kAB+kT4KPpEMFi68uCR7UTQgQFB1xj0BQSdf8jKAEAEgwf0U/Lgi44UA4MH9Fvy4Iwi1woAIW4Bs7Dy0JDiyFADzxYS9ADJ7VQAcjDXLAgkji0h8uCS0gDtRNDSAFETuvLQj1RQMJExnAGBAUDXIdcKAPLgjuLIygBYzxbJ7VST8sCN4gAQk1vbMeHXTNC01sNe"
        )
        super.init(code:code, seqno: seqno, workchain: workchain, publicKey: publicKey, walletId: walletId, plugins: plugins)
    }
}

/// Internal WalletV5 implementation. Use specific revision `WalletV5R1` instead.
public class WalletV5: WalletContract {
    public let seqno: Int64
    public let workchain: Int8
    public let publicKey: Data
    public let walletId: WalletId
    public let plugins: Set<Address>
    public let code: Cell
    
    fileprivate init(code: Cell,
                     seqno: Int64 = 0,
                     workchain: Int8 = 0,
                     publicKey: Data,
                     walletId: WalletId,
                     plugins: Set<Address> = []
    ) {
        self.code = code
        self.seqno = seqno
        self.workchain = workchain
        self.publicKey = publicKey
        
        self.walletId = walletId
        
        self.plugins = plugins
    }
    
    // TODO: support minimized version
    func storeWalletId() -> Builder {
        let context = try! Builder()
            .store(bit: true)
            .store(int: self.walletId.workchain, bits: 8)
            .store(uint: self.walletId.walletVersion, bits: 8)
            .store(uint: self.walletId.subwalletNumber, bits: 15)
            .endCell()
            .beginParse()
            .loadInt(bits: 32)

        return try! Builder()
            .store(int: self.walletId.networkGlobalId ^ Int32(context), bits: 32)
    }
    
    public var stateInit: StateInit {
        let data = try! Builder()
            .store(bit: true) // is signature auth allowed
            .store(uint: 0, bits: 32) // initial seqno
            .store(self.storeWalletId())
            .store(data: publicKey)
            .store(bit: 0)
            .endCell()
        
        return StateInit(code: self.code, data: data)
    }
    
    func pluginsCompact() -> Set<CompactAddress> {
        Set(self.plugins.map{ a in CompactAddress(a) })
    }
    
    /*
     out_list_empty$_ = OutList 0;
     out_list$_ {n:#} prev:^(OutList n) action:OutAction
     = OutList (n + 1);
     */
    private func storeOutList(messages: [MessageRelaxed], sendMode: UInt64) throws -> Builder {
        
        var latestCell = Builder()
        for message in messages {
            latestCell = try Builder()
                .store(uint: OpCodes.OUT_ACTION_SEND_MSG_TAG, bits: 32)
                .store(uint: sendMode, bits: 8)
                .store(ref: latestCell)
                .store(ref: try Builder().store(message))
        }
        
        return latestCell
    }
    
    private func storeOutListExtended(messages: [MessageRelaxed], sendMode: UInt64) throws -> Builder {
        try Builder()
            .storeMaybe(ref: self.storeOutList(messages: messages, sendMode: sendMode))
            .store(uint: 0, bits: 1)
    }
    
    public func createTransfer(args: WalletTransferData, messageType: MessageType = .ext) throws -> WalletTransfer {
        guard args.messages.count <= 255 else {
            throw TonError.custom("Maximum number of messages in a single transfer is 255")
        }
        
        let signingMessage = try Builder()
            .store(uint: messageType.opCode, bits: 32)
            .store(self.storeWalletId())
        
        if (args.seqno == 0) {
            // 32 bits with 1
            try signingMessage.store(uint: 0xFFFFFFFF, bits: 32)
        } else {
            let defaultTimeout = UInt64(Date().timeIntervalSince1970) + 60 // Default timeout: 60 seconds
            try signingMessage.store(uint: args.timeout ?? defaultTimeout, bits: 32)
        }

        try signingMessage
            .store(uint: args.seqno, bits: 32)
            .store(
                self.storeOutListExtended(
                    messages: args.messages,
                    sendMode: UInt64(args.sendMode.rawValue)
                )
            )
        
        return WalletTransfer(signingMessage: signingMessage, signaturePosition: .tail)
    }
}
