import Foundation

public protocol ContractProvider {
    func getState() async throws -> ContractState
    func get(name: String, args: [Tuple]) async throws -> TupleReader
    func external(message: Cell) async throws
    func `internal`(via sender: Sender, args: [String: Any]) async throws
}
