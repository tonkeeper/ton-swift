import Foundation

public struct Contract {
    private let address: Address
    private let initState: (code: Cell?, data: Cell?)?
        
    public static func addressFromStateInit(workchain: Int8, stateInit: StateInit) throws -> Address {
        let hash = try Builder()
            .store(stateInit)
            .endCell()
            .hash()
        
        return Address(workChain: workchain, hash: hash)
    }
}

// TBD: put under the contract code
func contractAddress(workchain: Int8, stateInit: StateInit) throws -> Address {
    let hash = try Builder()
        .store(stateInit)
        .endCell()
        .hash()
    
    return Address(workChain: workchain, hash: hash)
}
