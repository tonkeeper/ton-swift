import Foundation
import BigInt
import TweetNacl

final class WalletContractV1R1: WalletContract {
    let workchain: Int8
    let stateInit: StateInit
    let publicKey: Data
    
    init(workchain: Int8, publicKey: Data) throws {
        self.workchain = workchain
        self.publicKey = publicKey
        
        let bocString = "te6cckEBAQEARAAAhP8AIN2k8mCBAgDXGCDXCx/tRNDTH9P/0VESuvKhIvkBVBBE+RDyovgAAdMfMSDXSpbTB9QC+wDe0aTIyx/L/8ntVEH98Ik="
        let cell = try Cell.fromBoc(src: Data(base64Encoded: bocString)!)[0]
        let data = try Builder().storeUint(UInt64(0), bits: 32)
        try data.bits.write(data: publicKey)
        
        self.stateInit = StateInit(code: cell, data: try data.endCell())
    }
    
    func getSeqno(provider: ContractProvider) async throws -> UInt64 {
        let state = try await provider.getState()
        if case .active(_, let data) = state.state, let data {
            return try Cell.fromBoc(src: data)[0].beginParse().bits.loadUint(bits: 32)
        } else {
            return 0
        }
    }
    
    func createTransfer(args: WalletTransferData) throws -> Cell {
        let sendMode = args.sendMode ?? SendMode()
        let signingMessage = try Builder().storeUint(args.seqno, bits: 32)
        
        if let message = args.messages?.first {
            try signingMessage.storeUint(UInt64(sendMode.rawValue), bits: 8)
            try signingMessage.storeRef(cell: try Builder().store(message))
        }
        
        let signature = try NaclSign.sign(message: signingMessage.endCell().hash(), secretKey: args.secretKey)
        
        let body = Builder()
        try body.bits.write(data: signature)
        try body.store(signingMessage)
        
        return try body.endCell()
    }
    
}
