//
//  ContractStateStatus.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

import Foundation

public enum ContractStateStatus {
    case uninit
    case active(code: Data?, data: Data?)
    case frozen(stateHash: Data?)
}
