import Foundation
import TweetNacl

public enum Mnemonic {
    public static let words = String.englishMnemonics
    
    /**
     Generate new mnemonic
     
     - Parameter wordsCount: number of words to generate
     - Parameter password: mnemonic password
     - returns: mnemonic string
     */
    public static func mnemonicNew(wordsCount: Int = 24, password: String = "") -> [String] {
        var mnemonicArray: [String] = []
        
        while true {
            mnemonicArray = []
            let rnd = [Int](repeating: 0, count: wordsCount).map({ _ in Int.random(in: 0..<Int.max) })
            for i in 0..<wordsCount {
                mnemonicArray.append(words[rnd[i] % (words.count - 1)])
            }
            
            if password.count > 0 {
                if !isPasswordNeeded(mnemonicArray: mnemonicArray) {
                    continue
                }
            }
            
            if !isBasicSeed(entropy: mnemonicToEntropy(mnemonicArray: mnemonicArray, password: password)) {
                continue
            }
            
            break
        }
        
        return mnemonicArray
    }
    
    /**
     Validate Mnemonic
     
     - Parameter mnemonicArray: mnemonic array
     - Parameter password: mnemonic password
     - returns: true for valid mnemonic
     */
    public static func mnemonicValidate(mnemonicArray: [String], password: String = "") -> Bool {
        let mnemonicArray = normalizeMnemonic(src: mnemonicArray)
        
        for word in mnemonicArray {
            if !words.contains(word) {
                return false
            }
        }
        
        if password.count > 0 {
            if !isPasswordNeeded(mnemonicArray: mnemonicArray) {
                return false
            }
        }
        
        return isBasicSeed(entropy: mnemonicToEntropy(mnemonicArray: mnemonicArray, password: password))
    }
    
    /**
     Convert mnemonic to entropy
     
     - Parameter mnemonicArray: mnemonic array
     - Parameter password: mnemonic password
     - returns: 64 byte entropy
     */
    public static func mnemonicToEntropy(mnemonicArray: [String], password: String = "") -> Data {
        return hmacSha512(phrase: mnemonicArray.joined(separator: " "), password: password)
    }
    
    /**
     Convert mnemonic to seed
     
     - Parameter mnemonicArray: mnemonic array
     - Parameter password: mnemonic password
     - returns: 64 byte seed
     */
    public static func mnemonicToSeed(mnemonicArray: [String], password: String = "") -> Data {
        let entropy = mnemonicToEntropy(mnemonicArray: mnemonicArray, password: password)
        
        let salt = "TON default seed"
        let saltData = Data(salt.utf8)
        
        return Data(pbkdf2Sha512(phrase: entropy, salt: saltData))
    }
    
    /**
     Convert mnemonic to HD seed
     
     - Parameter mnemonicArray: mnemonic array
     - Parameter password: mnemonic password
     - returns: 64 byte seed
     */
    public static func mnemonicToHDSeed(mnemonicArray: [String], password: String = "") -> Data {
        let entropy = mnemonicToEntropy(mnemonicArray: mnemonicArray, password: password)
        
        let salt = "TON HD Keys seed"
        let saltData = Data(salt.utf8)
        
        return Data(pbkdf2Sha512(phrase: entropy, salt: saltData))
    }
    
    public static func isPasswordNeeded(mnemonicArray: [String]) -> Bool {
        let passlessEntropy = mnemonicToEntropy(mnemonicArray: mnemonicArray, password: "")
        return isPasswordSeed(entropy: passlessEntropy) && !isBasicSeed(entropy: passlessEntropy)
    }
    
    public static func isBasicSeed(entropy: Data) -> Bool {
        let salt = "TON seed version"
        let saltData = Data(salt.utf8)
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: max(1, pbkdf2Sha512Iterations / 256))
        
        return seed[0] == 0
    }
  
    public static func isMultiAccountSeed(mnemonicArray: [String]) -> Bool {
        let entropy = hmacSha512(phrase: "TON Keychain", password: mnemonicArray.joined(separator: " "))
      
        // There is a collision propability with TON mnemonics 
        if (isBasicSeed(entropy: mnemonicToEntropy(mnemonicArray: mnemonicArray, password: ""))) {
          return false
        }
      
        let salt = "TON Keychain Version"
        let saltData = Data(salt.utf8)
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: 1, keyLength: 64)
        
        return seed[0] == 0
    }
      
        
    public static func isPasswordSeed(entropy: Data) -> Bool {
        let salt = "TON fast seed version"
        let saltData = Data(salt.utf8)
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: 1)
        
        return seed[0] == 1
    }
    
    public static func normalizeMnemonic(src: [String]) -> [String] {
        return src.map({ $0.lowercased() })
    }
    
    public static func isValidBip39Mnemonic(mnemonicArray: [String]) -> Bool {
        let mnemonic = normalizeMnemonic(src: mnemonicArray)

        guard !mnemonic.isEmpty,
            mnemonic.allSatisfy({ words.contains($0) }),
            mnemonic.count % 3 == 0,
            (12...24).contains(mnemonic.count)
        else {
            return false
        }

        var bits = ""
        for word in mnemonic {
            guard let idx = words.firstIndex(of: word) else { return false }
            let bin = String(idx, radix: 2)
            bits += String(repeating: "0", count: 11 - bin.count) + bin
        }

        let entLength = mnemonic.count * 11 * 32 / 33
        let checksumLen = entLength / 32

        let entBits = bits.prefix(entLength)
        let csBits = bits.suffix(checksumLen)

        var entropyBytes: [UInt8] = []
        var i = entBits.startIndex
        while i < entBits.endIndex {
            let next = entBits.index(i, offsetBy: 8)
            let byteStr = String(entBits[i..<next])
            guard let byte = UInt8(byteStr, radix: 2) else { return false }
            entropyBytes.append(byte)
            i = next
        }

        let hashData = Data(entropyBytes).sha256()

        let hashBits =
            hashData
            .map { byte -> String in
                let bin = String(byte, radix: 2)
                return String(repeating: "0", count: 8 - bin.count) + bin
            }
            .joined()
            .prefix(checksumLen)

        return csBits == hashBits
    }
        
    public static func bip39MnemonicToSeed(mnemonicArray: [String], password: String = "") -> Data {
        let salt: (_ password: String) -> String = { password in
            let salt = "mnemonic" + password
            return salt
        }
        
        let mnemonicBuffer = Data(normalizeMnemonic(src: mnemonicArray).joined(separator: " ").utf8)
        let saltBuffer = Data(salt(password).utf8)
        
        let res = pbkdf2Sha512(phrase: mnemonicBuffer, salt: saltBuffer, iterations: 2048, keyLength: 64)
        
        return Data(res)
    }
    
    public static func bip39MnemonicToPrivateKey(mnemonicArray: [String]) throws -> KeyPair {
        guard isValidBip39Mnemonic(mnemonicArray: mnemonicArray) else {
            throw NSError(domain: "Mnemonic", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid mnemonic"])
        }
        
        let seed = bip39MnemonicToSeed(mnemonicArray: mnemonicArray)
        
        do {
            let derived = try Ed25519.derivePath(path: "m/44'/607'/0'", seed: seed.hexString())
            
            let keyPair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: derived.key)
            return KeyPair(publicKey: .init(data: keyPair.publicKey), privateKey: .init(data: keyPair.secretKey))
            
        } catch {
            throw error
        }
    }
    
    /**
     Extract private key from mnemonic
     
     - Parameter mnemonicArray: mnemonic array
     - Parameter password: mnemonic password
     - returns: KeyPair
     */
    public static func mnemonicToPrivateKey(mnemonicArray: [String], password: String = "") throws -> KeyPair {
        let mnemonicArray = normalizeMnemonic(src: mnemonicArray)
        let seed = mnemonicToSeed(mnemonicArray: mnemonicArray, password: password)[0..<32]
        
        do {
            let keyPair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: seed)
            return KeyPair(publicKey: .init(data: keyPair.publicKey), privateKey: .init(data: keyPair.secretKey))
            
        } catch {
            throw error
        }
    }
    
    public static func anyMnemonicToPrivateKey(mnemonicArray: [String], password: String = "") throws -> KeyPair {
        if(mnemonicValidate(mnemonicArray: mnemonicArray)) {
            return try mnemonicToPrivateKey(mnemonicArray: mnemonicArray)
        } else {
            return try bip39MnemonicToPrivateKey(mnemonicArray: mnemonicArray)
        }
    }
}
