import Foundation

public class LevelMask {
    private var _mask: UInt32 = 0
    private var _hashIndex: UInt32
    private var _hashCount: UInt32
    
    public init(mask: UInt32 = 0) {
        self._mask = mask
        self._hashIndex = countSetBits(self._mask)
        self._hashCount = self._hashIndex + 1
    }
    
    public var value: UInt32 {
        return _mask
    }
    
    public var level: UInt32 {
        return UInt32(32 - _mask.leadingZeroBitCount)
    }
    
    public var hashIndex: UInt32 {
        return _hashIndex
    }
    
    public var hashCount: UInt32 {
        return _hashCount
    }
    
    public func apply(level: UInt32) -> LevelMask {
        return LevelMask(mask: _mask & ((1 << level) - 1))
    }
    
    public func isSignificant(level: UInt32) -> Bool {
        return level == 0 || (_mask >> (level - 1)) % 2 != 0
    }
}

extension LevelMask: Hashable {
    public static func == (lhs: LevelMask, rhs: LevelMask) -> Bool {
        return lhs._mask == rhs._mask &&
        lhs._hashIndex == rhs._hashIndex &&
        lhs._hashCount == rhs._hashCount
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_mask)
        hasher.combine(_hashIndex)
        hasher.combine(_hashCount)
    }
}

func countSetBits(_ n: UInt32) -> UInt32 {
    var n = n - ((n >> 1) & 0x55555555)
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    
    return (n + (n >> 4) & 0xF0F0F0F) * 0x1010101 >> 24
}
