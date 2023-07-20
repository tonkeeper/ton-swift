//
//  Builder+Coins.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Builder {
    /// Write coins amount in varuint format
    @discardableResult
    func store(coins: Coins) throws -> Self {
        try store(varuint: coins.amount, limit: 16)
    }
    
    /**
     * Store optional coins value
     * @param amount amount of coins, null or undefined
     * @returns this builder
     */
    @discardableResult
    public func storeMaybe(coins: Coins?) throws -> Self {
        if let coins {
            try store(bit: true)
            try store(coins: coins)
        } else {
            try store(bit: false)
        }
        return self
    }
}
