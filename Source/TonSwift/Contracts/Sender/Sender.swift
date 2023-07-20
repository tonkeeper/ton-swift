public struct Sender {
    let address: Address?
    let send: ((SenderArguments) async throws -> Void)
}
