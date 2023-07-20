//
//  LevelMask.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public struct LevelMask: Hashable {
    private var _mask: UInt32 = 0
    private var _hashIndex: UInt32
    private var _hashCount: UInt32
    
    public init(mask: UInt32 = 0) {
        self._mask = mask
        self._hashIndex = countSetBits(self._mask)
        self._hashCount = self._hashIndex + 1
    }
    
    public var value: UInt32 {
        _mask
    }
    
    public var level: UInt32 {
        UInt32(32 - _mask.leadingZeroBitCount)
    }
    
    public var hashIndex: UInt32 {
        _hashIndex
    }
    
    public var hashCount: UInt32 {
        _hashCount
    }
    
    public func apply(level: UInt32) -> LevelMask {
        LevelMask(mask: _mask & ((1 << level) - 1))
    }
    
    public func isSignificant(level: UInt32) -> Bool {
        level == 0 || (_mask >> (level - 1)) % 2 != 0
    }

    // MARK: - Hashable

    public static func == (lhs: LevelMask, rhs: LevelMask) -> Bool {
        lhs._mask == rhs._mask &&
        lhs._hashIndex == rhs._hashIndex &&
        lhs._hashCount == rhs._hashCount
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_mask)
        hasher.combine(_hashIndex)
        hasher.combine(_hashCount)
    }
}
