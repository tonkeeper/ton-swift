import Foundation

public struct Address: Hashable, Codable, Equatable, CellCodable, StaticSize {
    public let workchain: Int8
    public let hash: Data
    
    /// Initializes address from raw components.
    public init(workchain: Int8, hash: Data) {
        self.workchain = workchain
        self.hash = hash
    }
    
    /// Generates a test address
    public static func mock(workchain: Int8, seed: String) -> Self {
        Address(workchain: workchain, hash: Data(seed.utf8).sha256())
    }

    /// Parses address from any format
    public static func parse(_ source: String) throws -> Address {
        source.firstIndex(of: ":") == nil ? try FriendlyAddress(string: source).address : try parse(raw: source)
    }
    
    /// Initializes address from the raw format `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public static func parse(raw: String) throws -> Address {
        let parts = raw.split(separator: ":")
        guard parts.count == 2 else {
            throw TonError.custom("Raw address is malformed: should be in the form `<workchain number>:<hex>`")
        }
        guard let wc = Int8(parts[0], radix: 10) else {
            throw TonError.custom("Raw address is malformed: workchain must be a decimal integer")
        }
        guard let hash = Data(hex: String(parts[1])) else {
            throw TonError.custom("Raw address is malformed: hash part should be correctly hex-encoded")
        }
        return Address(workchain: wc, hash: hash)
    }

    /// Returns raw format of the address: `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public func toRaw() -> String {
        "\(workchain):\(hash.hexString())"
    }
    
    /// Returns raw format of the address: `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public func toFriendly(testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> FriendlyAddress {
        FriendlyAddress(address: self, testOnly: testOnly, bounceable: bounceable)
    }
    
    /// Shortcut for constructing FriendlyAddress with all the options.
    public func toString(urlSafe: Bool = true, testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> String {
        toFriendly(testOnly: testOnly, bounceable: bounceable).toString(urlSafe: urlSafe)
    }

    // MARK: - Equatable

    public static func == (lhs: Address, rhs: Address) -> Bool {
        lhs.workchain != rhs.workchain ? false : lhs.hash == rhs.hash
    }

    // MARK: - CellCodable, StaticSize
    /// ```
    /// anycast_info$_ depth:(#<= 30) { depth >= 1 }
    ///                rewrite_pfx:(bits depth)        = Anycast;
    /// addr_std$10 anycast:(Maybe Anycast)
    ///             workchain_id:int8
    ///             address:bits256                    = MsgAddressInt;
    /// addr_var$11 anycast:(Maybe Anycast)
    ///             addr_len:(## 9)
    ///             workchain_id:int32
    ///             address:(bits addr_len)            = MsgAddressInt;
    /// ```
    
    public static var bitWidth: Int = 267
    
    public func storeTo(builder: Builder) throws {
        try builder
            .store(uint: 2, bits: 2)
            .store(uint: 0, bits: 1)
            .store(int: workchain, bits: 8)
            .store(data: hash)
    }
    
    public static func loadFrom(slice: Slice) throws -> Address {
        try slice.tryLoad { s in
            let type = try s.loadUint(bits: 2)
            if type != 2 {
                throw TonError.custom("Unsupported address type: expecting internal address `addr_std$10`")
            }
            
            // No Anycast supported
            let anycastPrefix = try s.loadUint(bits: 1)
            if anycastPrefix != 0 {
                throw TonError.custom("Invalid address: anycast not supported")
            }

            // Read address
            let wc = Int8(try s.loadInt(bits: 8))
            let hash = try s.loadBytes(32)

            return Address(workchain: wc, hash: hash)
        }
    }
}
