//
//  StaticSize.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Types implement KnownSize protocol when they have statically-known size in bits
public protocol StaticSize {
    /// Size of the type in bits
    static var bitWidth: Int { get }
}
