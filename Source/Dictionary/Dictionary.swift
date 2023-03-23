import BigInt

public typealias DictionaryKeyTypes = Hashable

/// Every type that can be used as a dictionary key has an accompanying coder object configured to read that type.
public protocol DictionaryKeyCoder: TypeCoder {
    var bits: Int { get }
}

/// Every type that can be used as a dictionary value has an accompanying coder object configured to read that type.
public protocol TypeCoder {
    func serialize(src: any DictionaryKeyTypes, builder: Builder) throws
    func parse(src: Slice) throws -> any DictionaryKeyTypes
}


public class Dictionary<K: DictionaryKeyTypes, V: Hashable> {
    
    /**
     Create an empty map
    - parameter key: key type
    - parameter value: value type
    - returns Dictionary
    */
    public static func empty(key: DictionaryKeyCoder? = nil, value: (any TypeCoder)? = nil) -> Dictionary {
        return Dictionary(values: [:], key: key, value: value)
    }
    
    /**
     Load dictionary from slice
    - parameter key: key description
    - parameter value: value description
    - parameter src: slice
    - returns Dictionary
    */
    public static func load(key: DictionaryKeyCoder, value: any TypeCoder, sc: Slice) throws -> Dictionary {
        let cell = try sc.loadMaybeRef()
        if let cell, !cell.isExotic {
            return try loadDirect(key: key, value: value, sc: cell.beginParse())
        } else {
            return .empty(key: key, value: value)
        }
    }
    
    public static func load(key: DictionaryKeyCoder, value: any TypeCoder, sc: Cell) throws -> Dictionary {
        // TODO: maybe it would be better to add type "AnyCell" and keep "Cell" for non-exotic cell and avoid these decisions here.
        // Steve Korshakov says the reason for this is that pruned branches should yield empty dicts somewhere down the line.
        if sc.isExotic {
            return .empty(key: key, value: value)
        }
        
        let slice = try sc.beginParse()
        return try load(key: key, value: value, sc: slice)
    }

    /**
     Low level method for rare dictionaries from system contracts.
    Loads dictionary from slice directly without going to the ref.

    - parameter key: key description
    - parameter value: value description
    - parameter sc: slice
    - returns Dictionary
    */
    static func loadDirect(key: DictionaryKeyCoder, value: any TypeCoder, sc: Slice?) throws -> Dictionary {
        guard let sc = sc else {
            return Dictionary.empty(key: key, value: value)
        }

        let slice = sc
        let values = try parseDict(sc: slice, keySize: key.bits, extractor: value.parse)
        var prepare = [String: V]()
        for (k, v) in values {
            let keyValue = try key.parse(src: Cell(bits: k).beginParse())
            prepare[try serializeInternalKey(value: keyValue)] = v as? V
        }
        
        return Dictionary(values: prepare, key: key, value: value)
    }
    static func loadDirect(key: DictionaryKeyCoder, value: any TypeCoder, sc: Cell?) throws -> Dictionary {
        return try loadDirect(key: key, value: value, sc: sc?.beginParse())
    }
    
    private var key: DictionaryKeyCoder?
    private var value: (any TypeCoder)?
    private var map: [String: V]

    private init(values: [String: V], key: DictionaryKeyCoder?, value: (any TypeCoder)?) {
        self.key = key
        self.value = value
        self.map = values
    }
    
    var size: Int {
        return map.count
    }
    
    func get(key: K) throws -> V? {
        return map[try serializeInternalKey(value: key)]
    }
    
    func has(key: K) throws -> Bool {
        return try map.contains(where: { $0.key == (try serializeInternalKey(value: key)) })
    }
    
    func set(key: K, value: V) throws {
        map[try serializeInternalKey(value: key)] = value
    }
    
    func delete(key: K) throws -> Bool {
        let k = try serializeInternalKey(value: key)
        return (map.removeValue(forKey: k) != nil)
    }
    
    func clear() {
        map = [:]
    }
    
    func keys() throws -> [K] {
        return try Array(map.keys).map { try deserializeInternalKey(value: $0) as! K }
    }
    
    func values() -> [V] {
        return Array(map.values)
    }
    
    func store(builder: Builder, key: (any DictionaryKeyCoder)? = nil, value: (any TypeCoder)? = nil) throws {
        if size == 0 {
            try builder.bits.write(bit: false)
            return
        }
        
        // Resolve serializer
        var resolvedKey = self.key
        if let key = key {
            resolvedKey = key
        }
        
        var resolvedValue = self.value
        if let value = value {
            resolvedValue = value
        }
        
        guard let resolvedKey = resolvedKey else {
            throw TonError.custom("Key serializer is not defined")
        }
        guard let resolvedValue = resolvedValue else {
            throw TonError.custom("Value serializer is not defined")
        }
        
        // Prepare map
        var prepared = [BitString: V]()
        for (k, v) in map {
            let src = try deserializeInternalKey(value: k)
            let builder = Builder()
            try resolvedKey.serialize(src: src, builder: builder)
            let bitstring = try builder.endCell().bits
            prepared[bitstring] = v
        }
        
        // Store
        try builder.bits.write(bit: true)
        let dd = Builder()
        try serializeDict(src: prepared, keyLength: resolvedKey.bits, serializer: { value, builder in
            try resolvedValue.serialize(src: value, builder: builder)
        }, to: dd)
        try builder.storeRef(cell: dd.endCell())
    }
    
    func storeDirect(builder: Builder, key: (any DictionaryKeyCoder)? = nil, value: (any TypeCoder)? = nil) throws {
        if size == 0 {
            throw TonError.custom("Cannot store empty dictionary directly")
        }
        
        // Resolve serializer
        var resolvedKey = self.key
        if let key = key {
            resolvedKey = key
        }
        
        var resolvedValue = self.value
        if let value = value {
            resolvedValue = value
        }
        
        guard let resolvedKey = resolvedKey else {
            throw TonError.custom("Key serializer is not defined")
        }
        guard let resolvedValue = resolvedValue else {
            throw TonError.custom("Value serializer is not defined")
        }
        
        // Prepare map
        var prepared = [BitString: V]()
        for (k, v) in map {
            let src = try deserializeInternalKey(value: k)
            let builder = Builder()
            try resolvedKey.serialize(src: src, builder: builder)
            let bitstring = try builder.endCell().bits
            prepared[bitstring] = v
        }
        
        // Store
        try serializeDict(src: prepared, keyLength: resolvedKey.bits, serializer: { value, builder in
            try resolvedValue.serialize(src: value, builder: builder)
        }, to: builder)
    }
}
