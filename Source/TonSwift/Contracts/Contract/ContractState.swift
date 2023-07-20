//
//  ContractState.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

public struct ContractState {
    let balance: BigInt
    let last: ContractStateLast?
    let state: ContractStateStatus
}
