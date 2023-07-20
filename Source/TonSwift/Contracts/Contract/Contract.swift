import Foundation
import BigInt

/// Common interface for all contracts that allows computing contract addresses and messages
public protocol Contract {
    var workchain: Int8 { get }
    var stateInit: StateInit { get }
    func address() throws -> Address
}

extension Contract {
    public func address() throws -> Address {
        let hash = try Builder().store(stateInit).endCell().hash()
        return Address(workchain: workchain, hash: hash)
    }
}
