import BigInt

struct WalletTransferData {
    let seqno: UInt64
    let secretKey: Data
    let messages: [MessageRelaxed]?
    let sendMode: SendMode?
}

protocol WalletContract: Contract {
    func getBalance(provider: ContractProvider) async throws -> BigInt
    func getSeqno(provider: ContractProvider) async throws -> UInt64
    func send(provider: ContractProvider, message: Cell) async throws
    func sendTransfer(provider: ContractProvider, args: WalletTransferData) async throws
    func createTransfer(args: WalletTransferData) throws -> Cell
    func sender(provider: ContractProvider, secretKey: Data) async throws -> Sender
}

extension WalletContract {
    func getBalance(provider: ContractProvider) async throws -> BigInt {
        let state = try await provider.getState()
        return state.balance
    }
    
    func send(provider: ContractProvider, message: Cell) async throws {
        try await provider.external(message: message)
    }
    
    func sendTransfer(provider: ContractProvider, args: WalletTransferData) async throws {
        let transfer = try createTransfer(args: args)
        try await send(provider: provider, message: transfer)
    }
    
    func sender(provider: ContractProvider, secretKey: Data) async throws -> Sender {
        return Sender(
            address: nil,
            send: { args in
                let seqno = try await self.getSeqno(provider: provider)
                let message = MessageRelaxed.internal(
                    to: args.to,
                    value: args.value,
                    bounce: args.bounce,
                    stateInit: args.stateInit,
                    body: args.body
                )
                let args = WalletTransferData(
                    seqno: seqno,
                    secretKey: secretKey,
                    messages: [message],
                    sendMode: args.sendMode
                )
                let transfer = try self.createTransfer(args: args)
            }
        )
    }
}
