//
//  DictionaryCoder.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

// TODO: class too big - find how to make it less
/// Coder for the dictionaries that stores the coding rules for keys and values.
/// Use this explicit API when working with dynamically-sized dictionary keys.
/// In all other cases use `Dictionary<K,V>` type where the key size is known at compile time.
public class DictionaryCoder<K: TypeCoder, V: TypeCoder> where K.T: Hashable {
    let keyLength: Int
    let keyCoder: K
    let valueCoder: V
    
    init(keyLength: Int, _ keyCoder: K, _ valueCoder: V) {
        self.keyLength = keyLength
        self.keyCoder = keyCoder
        self.valueCoder = valueCoder
    }

    static func `default`<KT,VT>() -> DictionaryCoder<K,V>
        where KT: CellCodable & StaticSize & Hashable,
              VT: CellCodable,
              K == DefaultCoder<KT>,
              V == DefaultCoder<VT> {
        DictionaryCoder(
            keyLength: KT.bitWidth,
            DefaultCoder<KT>(),
            DefaultCoder<VT>()
       )
    }

    // MARK: Public methods

    /// Loads dictionary from slice
    public func load(_ slice: Slice) throws -> [K.T:V.T] {
        let cell = try slice.loadMaybeRef()
        if let cell, !cell.isExotic {
            return try loadRoot(cell.beginParse())
        } else {
            // TODO: review this decision to return empty dicts from exotic cells
            // Steve Korshakov says the reason for this is that
            // pruned branches should yield empty dicts somewhere down the line.
            return [:]
        }
    }
    
    /// Loads root of the dictionary directly from a slice
    public func loadRoot(_ slice: Slice) throws -> [K.T:V.T] {
        var map = [K.T: V.T]()
        try doParse(prefix: Builder(), slice: slice, n: keyLength, result: &map)
        return map
    }

    // MARK: Internal methods

    func store(map: [K.T: V.T], builder: Builder) throws {
        if map.count == 0 {
            try builder.store(bit: 0)
        } else {
            try builder.store(bit: 1)
            let subcell = Builder()
            try storeRoot(map: map, builder: subcell)
            try builder.store(ref: try subcell.endCell())
        }
    }
    
    func storeRoot(map: [K.T: V.T], builder: Builder) throws {
        if map.count == 0 {
            throw TonError.custom("Cannot store empty dictionary directly")
        }
                
        // Serialize keys
        var paddedMap: [Bitstring: V.T] = [:]
        for (key, value) in map {
            let builder = Builder()
            try keyCoder.storeValue(key, to: builder)
            let keybits = builder.bitstring()
            let paddedKey = keybits.padLeft(keyLength)
            paddedMap[paddedKey] = value
        }

        // Calculate root label
        let rootEdge = try buildEdge(paddedMap)
        try writeEdge(src: rootEdge, keyLength: keyLength, valueCoder: valueCoder, to: builder)
    }

    func findCommonPrefix(src: some Collection<Bitstring>) -> Bitstring {
        // Corner cases
        if src.isEmpty {
            return Bitstring()
        }
        if src.count == 1 {
            return src.first!
        }

        // Searching for prefix
        let sorted = src.sorted()
        let first = sorted.first!
        let last = sorted.last!

        var size = 0
        for i in 0..<first.length {
            if (first.at(unchecked: i) != last.at(unchecked: i)) {
                break
            }
            size += 1
        }
        
        return try! first.substring(offset: 0, length: size)
    }

    // MARK: Private methods

    private func doParse(prefix: Builder, slice: Slice, n: Int, result: inout [K.T: V.T]) throws {
        // Reading label
        let k = bitsForInt(n)
        var pfxlen: Int = 0
        
        // short mode: $0
        if try slice.loadBit() == 0 {
            // Read
            pfxlen = try Unary.loadFrom(slice: slice).value
            try prefix.store(bits: try slice.loadBits(pfxlen))
        } else {
            // long mode: $10
            if try slice.loadBit() == 0 {
                pfxlen = Int(try slice.loadUint(bits: k))
                try prefix.store(bits: try slice.loadBits(pfxlen))
            // same mode: $11
            } else {
                // Same label detected
                let bit = try slice.loadBit()
                pfxlen = Int(try slice.loadUint(bits: k))
                try prefix.store(bit: bit, repeat: pfxlen)
            }
        }
        
        // We did read the whole prefix and reached the leaf:
        // parse the value and store it in the dictionary.
        if n - pfxlen == 0 {
            let fullkey = prefix.bitstring()
            let parsedKey = try keyCoder.loadValue(from: Cell(bits: fullkey).beginParse())
            result[parsedKey] = try valueCoder.loadValue(from: slice)
        } else {
            // We have to drill down the tree
            let left = try slice.loadRef()
            let right = try slice.loadRef()
            // Note: left and right branches implicitly contain prefixes '0' and '1'
            if !left.isExotic {
                let prefixleft = prefix.clone()
                try prefixleft.store(bit: 0)
                try doParse(prefix: prefixleft, slice: left.beginParse(), n: n - pfxlen - 1, result: &result)
            }
            if !right.isExotic {
                let prefixright = prefix.clone()
                try prefixright.store(bit: 1)
                try doParse(prefix: prefixright, slice: right.beginParse(), n: n - pfxlen - 1, result: &result)
            }
        }
    }

    private func buildNode<T>(_ src: [Bitstring: T]) throws -> Node<T> {
        try invariant(!src.isEmpty)
        if src.count == 1 {
            return .leaf(value: src.values.first!)
        } else {
            let (left, right) = try forkMap(src)
            return .fork(left: try buildEdge(left), right: try buildEdge(right))
        }
    }

    private func buildEdge<T>(_ src: [Bitstring: T]) throws -> Edge<T> {
        try invariant(!src.isEmpty)
        let label = findCommonPrefix(src: Array(src.keys))
        return Edge(label: label, node: try buildNode(removePrefixMap(src, label.length)))
    }

    /// Removes `n` bits from all the keys in a map
    private func removePrefixMap<T>(_ src: [Bitstring: T], _ length: Int) -> [Bitstring: T] {
        if length == 0 {
            return src
        }
        var res: [Bitstring: T] = [:]
        for (k, d) in src {
            res[try! k.dropFirst(length)] = d
        }
        return res
    }

    private func writeNode<T, V>(src: Node<T>, keyLength: Int, valueCoder: V, to builder: Builder) throws where V: TypeCoder, V.T == T {
        switch src {
        case .fork(let left, let right):
            let leftCell = Builder()
            let rightCell = Builder()
            
            try writeEdge(src: left, keyLength: keyLength - 1, valueCoder: valueCoder, to: leftCell)
            try writeEdge(src: right, keyLength: keyLength - 1, valueCoder: valueCoder, to: rightCell)
            
            try builder.store(ref: leftCell)
            try builder.store(ref: rightCell)
            
        case .leaf(let value):
            try valueCoder.storeValue(value, to: builder)
        }
    }

    private func writeEdge<T, V>(src: Edge<T>, keyLength: Int, valueCoder: V, to: Builder) throws where V: TypeCoder, V.T == T {
        try writeLabel(src: src.label, keyLength: keyLength, to: to)
        try writeNode(src: src.node, keyLength: keyLength - src.label.length, valueCoder: valueCoder, to: to)
    }

    /// Splits the dictionary by the value of the first bit of the keys. 0-prefixed keys go into left map, 1-prefixed keys go into the right one.
    /// First bit is removed from the keys.
    private func forkMap<T>(_ src: [Bitstring: T]) throws -> (left: [Bitstring: T], right: [Bitstring: T]) {
        try invariant(!src.isEmpty)
        
        var left: [Bitstring: T] = [:]
        var right: [Bitstring: T] = [:]
        for (k, d) in src {
            if k.at(unchecked: 0) == 0 {
                left[try! k.dropFirst(1)] = d
            } else {
                right[try! k.dropFirst(1)] = d
            }
        }
        
        try invariant(!left.isEmpty)
        try invariant(!right.isEmpty)
        return (left, right)
    }

    /// Deterministically produces optimal label type for a given label.
    /// This implementation is equivalent to the C++ reference implementation, and resolves the ties in the same way.
    ///
    /// From crypto/vm/dict.cpp:
    /// ```
    /// void append_dict_label_same(CellBuilder& cb, bool same, int len, int max_len) {
    ///   int k = 32 - td::count_leading_zeroes32(max_len);
    ///   assert(len >= 0 && len <= max_len && max_len <= 1023);
    ///   // options: mode '0', requires 2n+2 bits (always for n=0)
    ///   // mode '10', requires 2+k+n bits (only for n<=1)
    ///   // mode '11', requires 3+k bits (for n>=2, k<2n-1)
    ///   if (len > 1 && k < 2 * len - 1) {
    ///     // mode '11'
    ///     cb.store_long(6 + same, 3).store_long(len, k);
    ///   } else if (k < len) {
    ///     // mode '10'
    ///     cb.store_long(2, 2).store_long(len, k).store_long(-static_cast<int>(same), len);
    ///   } else {
    ///     // mode '0'
    ///     cb.store_long(0, 1).store_long(-2, len + 1).store_long(-static_cast<int>(same), len);
    ///   }
    /// }
    ///
    /// void append_dict_label(CellBuilder& cb, td::ConstBitPtr label, int len, int max_len) {
    ///   assert(len <= max_len && max_len <= 1023);
    ///   if (len > 0 && (int)td::bitstring::bits_memscan(label, len, *label) == len) {
    ///     return append_dict_label_same(cb, *label, len, max_len);
    ///   }
    ///   int k = 32 - td::count_leading_zeroes32(max_len);
    ///   // two options: mode '0', requires 2n+2 bits
    ///   // mode '10', requires 2+k+n bits
    ///   if (k < len) {
    ///     cb.store_long(2, 2).store_long(len, k);
    ///   } else {
    ///     cb.store_long(0, 1).store_long(-2, len + 1);
    ///   }
    ///   if ((int)cb.remaining_bits() < len) {
    ///     throw VmError{Excno::cell_ov, "cannot store a label into a dictionary cell"};
    ///   }
    ///   cb.store_bits(label, len);
    /// }
    /// ```
    private func writeLabel(src: Bitstring, keyLength: Int, to: Builder) throws {
        let k = bitsForInt(keyLength)
        let n = src.length
       
        // The goal is to choose the shortest encoding.
        // In case of a tie, choose a lexicographically shorter one.
        // Therefore, `short$0` comes ahead of `long$10` which is ahead of `same$11`.
        //
        // short mode '0' requires 2n+2 bits (always used for n=0)
        // long mode '10' requires 2+k+n bits (used only for n<=1)
        // same mode '11' requires 3+k bits (for n>=2, k<2n-1)
        if let bit = src.repeatsSameBit(), n > 1 && k < 2 * n - 1 { // same mode '11'
            try to.store(bits: 1, 1)       // header
            try to.store(bit: bit)         // value
            try to.store(uint: n, bits: k) // length
        } else if k < n { // long mode '10'
            try to.store(bits: 1, 0)       // header
            try to.store(uint: n, bits: k) // length
            try to.store(bits: src)        // the string itself
        } else { // short mode '0'
            try to.store(bit: 0)     // header
            try to.store(Unary(n))        // unary length prefix: 1{n}0
            try to.store(bits: src)  // the string itself
        }
    }

    private func invariant(_ cond: Bool) throws {
        if !cond { throw TonError.custom("Internal inconsistency") }
    }
}
