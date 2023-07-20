//
//  CommonMsgInfoExternalOut.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public struct CommonMsgInfoExternalOut {
    let src: Address
    let dest: ExternalAddress?
    let createdLt: UInt64
    let createdAt: UInt32
}
