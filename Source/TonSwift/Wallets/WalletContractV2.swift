import Foundation
import BigInt
import TweetNacl

public enum WalletContractV2Revision {
    case r1, r2
}

public final class WalletContractV2: WalletContract {
    public let workchain: Int8
    public let stateInit: StateInit
    public let publicKey: Data
    public let revision: WalletContractV2Revision
    
    public init(workchain: Int8, publicKey: Data, revision: WalletContractV2Revision) throws {
        self.workchain = workchain
        self.publicKey = publicKey
        self.revision = revision
        
        var bocString: String
        switch revision {
        case .r1:
            bocString = "te6cckEBAQEAVwAAqv8AIN0gggFMl7qXMO1E0NcLH+Ck8mCDCNcYINMf0x8B+CO78mPtRNDTH9P/0VExuvKhA/kBVBBC+RDyovgAApMg10qW0wfUAvsA6NGkyMsfy//J7VShNwu2"
            
        case .r2:
            bocString = "te6cckEBAQEAYwAAwv8AIN0gggFMl7ohggEznLqxnHGw7UTQ0x/XC//jBOCk8mCDCNcYINMf0x8B+CO78mPtRNDTH9P/0VExuvKhA/kBVBBC+RDyovgAApMg10qW0wfUAvsA6NGkyMsfy//J7VQETNeh"
        }
        
        let cell = try Cell.fromBoc(src: Data(base64Encoded: bocString)!)[0]
        let data = try Builder().storeUint(UInt64(0), bits: 32)
        try data.bits.write(data: publicKey)
        
        self.stateInit = StateInit(code: cell, data: try data.endCell())
    }
    
    public func createTransfer(args: WalletTransferData) throws -> Cell {
        guard args.messages.count <= 4 else {
            throw TonError.custom("Maximum number of messages in a single transfer is 4")
        }
        
        let signingMessage = try Builder().storeUint(args.seqno, bits: 32)
        if args.seqno == 0 {
            for _ in 0..<32 {
                try signingMessage.bits.write(bit: 1)
            }
        } else {
            let defaultTimeout = UInt64(Date().timeIntervalSince1970) + 60 // Default timeout: 60 seconds
            try signingMessage.storeUint(args.timeout ?? defaultTimeout, bits: 32)
        }
        
        for message in args.messages {
            try signingMessage.storeUint(UInt64(args.sendMode.rawValue), bits: 8)
            try signingMessage.storeRef(cell: try Builder().store(message))
        }
        
        let signature = try NaclSign.sign(message: signingMessage.endCell().hash(), secretKey: args.secretKey)
        
        let body = Builder()
        try body.bits.write(data: signature)
        try body.store(signingMessage)
        
        return try body.endCell()
    }
}
