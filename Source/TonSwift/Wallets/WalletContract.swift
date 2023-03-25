import BigInt

public struct WalletTransferData {
    public let seqno: UInt64
    public let secretKey: Data
    public let messages: [MessageRelaxed]
    public let sendMode: SendMode
    public let timeout: UInt64?
}

public protocol WalletContract: Contract {
    func getBalance(provider: ContractProvider) async throws -> BigInt
    func getSeqno(provider: ContractProvider) async throws -> UInt64
    func send(provider: ContractProvider, message: Cell) async throws
    func sendTransfer(provider: ContractProvider, args: WalletTransferData) async throws
    func createTransfer(args: WalletTransferData) throws -> Cell
    func sender(provider: ContractProvider, secretKey: Data) async throws -> Sender
}

extension WalletContract {
    public func getBalance(provider: ContractProvider) async throws -> BigInt {
        let state = try await provider.getState()
        return state.balance
    }
    
    public func send(provider: ContractProvider, message: Cell) async throws {
        try await provider.external(message: message)
    }
    
    public func sendTransfer(provider: ContractProvider, args: WalletTransferData) async throws {
        let transfer = try createTransfer(args: args)
        try await send(provider: provider, message: transfer)
    }
    
    public func sender(provider: ContractProvider, secretKey: Data) async throws -> Sender {
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
                    sendMode: args.sendMode,
                    timeout: nil
                )
                let transfer = try self.createTransfer(args: args)
                try await send(provider: provider, message: transfer)
            }
        )
    }
}
