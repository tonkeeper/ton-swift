import Foundation
import BigInt

public struct ContractState {
    let balance: BigInt
    let last: ContractStateLast?
    let state: ContractStateStatus
}

public struct ContractStateLast {
    let lt: BigInt
    let hash: Data
}

public enum ContractStateStatus {
    case uninit
    case active(code: Data?, data: Data?)
    case frozen(stateHash: Data?)
}
