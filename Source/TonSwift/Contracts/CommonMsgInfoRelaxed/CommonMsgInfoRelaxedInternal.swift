//
//  CommonMsgInfoRelaxedInternal.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public struct CommonMsgInfoRelaxedInternal {
    let ihrDisabled: Bool
    let bounce: Bool
    let bounced: Bool
    let src: AnyAddress
    let dest: Address
    let value: CurrencyCollection
    let ihrFee: Coins
    let forwardFee: Coins
    let createdLt: UInt64
    let createdAt: UInt32
}
