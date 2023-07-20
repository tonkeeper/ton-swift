//
//  CellType.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public enum CellType: Int {
    case ordinary = -1
    case prunedBranch = 1
    case merkleProof = 3
    case merkleUpdate = 4
}
