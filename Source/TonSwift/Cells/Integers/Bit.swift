//
//  Bit.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// All APIs that take bit as a parameter or return a bit are expressed using typealias `Bit` based on `Int`.
/// An API that produces `Bit` guarantees that it is in range `[0,1]`.
public typealias Bit = Int
