//
//  SenderArguments.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import BigInt

public struct SenderArguments {
    let value: BigUInt
    let to: Address
    let sendMode: SendMode
    let bounce: Bool
    let stateInit: StateInit?
    let body: Cell
}
