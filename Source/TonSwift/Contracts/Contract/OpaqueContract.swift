//
//  OpaqueContract.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public struct OpaqueContract: Contract {
    public let workchain: Int8
    public let stateInit: StateInit
    
    init(workchain: Int8, stateInit: StateInit) {
        self.workchain = workchain
        self.stateInit = stateInit
    }
}
