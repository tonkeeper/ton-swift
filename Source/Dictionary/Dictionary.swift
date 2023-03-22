import BigInt

public typealias DictionaryKeyTypes = Hashable

public protocol DictionaryKey {
    var bits: Int { get }
    func serialize(src: any DictionaryKeyTypes) throws -> BigInt
    func parse(src: BigInt) throws -> any DictionaryKeyTypes
}

public protocol DictionaryValue {
    func serialize(src: any DictionaryKeyTypes, builder: Builder) throws
    func parse(src: Slice) throws -> any DictionaryKeyTypes
}

public enum DictionaryKeys {
    public static func Address() -> DictionaryKey {
        return DictionaryKeyAddress()
    }

    public static func BigInt(bits: Int) -> DictionaryKey {
        return DictionaryKeyBigInt(bits: bits)
    }

    public static func Int(bits: Int) -> DictionaryKey {
        return DictionaryKeyInt(bits: bits)
    }

    public static func BigUint(bits: Int) -> DictionaryKey {
        return DictionaryKeyBigUInt(bits: bits)
    }

    public static func Uint(bits: Int) -> DictionaryKey {
        return DictionaryKeyUInt(bits: bits)
    }

    public static func Buffer(bytes: Int) -> DictionaryKey {
        return DictionaryKeyBuffer(bytes: bytes)
    }
}

public enum DictionaryValues {
    public static func BigInt(bits: Int) -> DictionaryValue {
        return DictionaryBigIntValue(bits: bits)
    }
    
    public static func Int(bits: Int) -> DictionaryValue {
        return DictionaryIntValue(bits: bits)
    }
    
    public static func BigUint(bits: Int) -> DictionaryValue {
        return DictionaryBigUIntValue(bits: bits)
    }
    
    public static func BigVarUint(bits: Int) -> DictionaryValue {
        return DictionaryBigVarUIntValue(bits: bits)
    }
    
    public static func Uint(bits: Int) -> DictionaryValue {
        return DictionaryUIntValue(bits: bits)
    }
    
    public static func Bool() -> DictionaryValue {
        return DictionaryBoolValue()
    }
    
    public static func Address() -> DictionaryValue {
        return DictionaryAddressValue()
    }
    
    public static func Cell() -> DictionaryValue {
        return DictionaryCellValue()
    }
    
    public static func Buffer(bytes: Int) -> DictionaryValue {
        return DictionaryBufferValue(bytes: bytes)
    }
}

public class Dictionary<K: DictionaryKeyTypes, V: Hashable> {
    
    /**
     Create an empty map
    - parameter key: key type
    - parameter value: value type
    - returns Dictionary
    */
    public static func empty(key: DictionaryKey? = nil, value: (any DictionaryValue)? = nil) -> Dictionary {
        return Dictionary(values: [:], key: key, value: value)
    }
    
    /**
     Load dictionary from slice
    - parameter key: key description
    - parameter value: value description
    - parameter src: slice
    - returns Dictionary
    */
    public static func load(key: DictionaryKey, value: any DictionaryValue, sc: Slice) throws -> Dictionary {
        let cell = try sc.loadMaybeRef()
        if let cell, !cell.isExotic {
            return try loadDirect(key: key, value: value, sc: cell.beginParse())
        } else {
            return .empty(key: key, value: value)
        }
    }
    
    public static func load(key: DictionaryKey, value: any DictionaryValue, sc: Cell) throws -> Dictionary {
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
    static func loadDirect(key: DictionaryKey, value: any DictionaryValue, sc: Slice?) throws -> Dictionary {
        guard let sc = sc else {
            return Dictionary.empty(key: key, value: value)
        }

        let slice = sc
        let values = try parseDict(sc: slice, keySize: UInt64(key.bits), extractor: value.parse)
        var prepare = [String: V]()
        for (k, v) in values {
            let keyValue = try key.parse(src: k)
            prepare[try serializeInternalKey(value: keyValue)] = v as? V
        }
        
        return Dictionary(values: prepare, key: key, value: value)
    }
    static func loadDirect(key: DictionaryKey, value: any DictionaryValue, sc: Cell?) throws -> Dictionary {
        return try loadDirect(key: key, value: value, sc: sc?.beginParse())
    }
    
    private var key: DictionaryKey?
    private var value: (any DictionaryValue)?
    private var map: [String: V]

    private init(values: [String: V], key: DictionaryKey?, value: (any DictionaryValue)?) {
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
    
    func store(builder: Builder, key: (any DictionaryKey)? = nil, value: (any DictionaryValue)? = nil) throws {
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
        var prepared = [BigInt: V]()
        for (k, v) in map {
            let src = try deserializeInternalKey(value: k)
            prepared[try resolvedKey.serialize(src: src)] = v
        }
        
        // Store
        try builder.bits.write(bit: true)
        let dd = Builder()
        try serializeDict(src: prepared, keyLength: resolvedKey.bits, serializer: { value, builder in
            try resolvedValue.serialize(src: value, builder: builder)
        }, to: dd)
        try builder.storeRef(cell: dd.endCell())
    }
    
    func storeDirect(builder: Builder, key: (any DictionaryKey)? = nil, value: (any DictionaryValue)? = nil) throws {
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
        var prepared = [BigInt: V]()
        for (k, v) in map {
            let src = try deserializeInternalKey(value: k)
            prepared[try resolvedKey.serialize(src: src)] = v
        }
        
        // Store
        try serializeDict(src: prepared, keyLength: resolvedKey.bits, serializer: { value, builder in
            try resolvedValue.serialize(src: value, builder: builder)
        }, to: builder)
    }
}
