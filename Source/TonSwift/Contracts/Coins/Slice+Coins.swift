//
//  Slice+Coins.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

extension Slice {
    /// Loads Coins value
    public func loadCoins() throws -> Coins {
        try loadType()
    }
    
    /// Preloads Coins value
    public func preloadCoins() throws -> Coins {
        try preloadType()
    }
    
    /// Load optionals Coins value.
    public func loadMaybeCoins() throws -> Coins? {
        try loadBoolean() ? try loadCoins() : nil
    }
}
