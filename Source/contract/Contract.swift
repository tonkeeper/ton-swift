import Foundation

public struct Contract {
    private let address: Address
    private let initState: (code: Cell?, data: Cell?)?
    private let abi: ContractABI?
}
