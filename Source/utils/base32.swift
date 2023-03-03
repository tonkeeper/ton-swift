import Foundation

fileprivate let alphabet = "abcdefghijklmnopqrstuvwxyz234567"

func base32Encode(buffer: Data) -> String {
    let length = buffer.count
    var bits = 0
    var value = 0
    var output = ""
    
    for i in 0..<length {
        value = (value << 8) | Int(buffer[i])
        bits += 8
        
        while bits >= 5 {
            output.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: (value >> (bits - 5)) & 31)])
            bits -= 5
        }
    }
    if bits > 0 {
        output.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: (value << (5 - bits)) & 31)])
    }
    
    return output
}

func readChar(alphabet: String, char: Character) throws -> Int {
    if let idx = alphabet.firstIndex(of: char) {
        return alphabet.distance(from: alphabet.startIndex, to: idx)
    } else {
        throw TonError.custom("Invalid character found: \(char)")
    }
}

func base32Decode(input: String) throws -> Data {
    let cleanedInput = input.lowercased()
    let length = cleanedInput.count
    var bits = 0
    var value = 0
    
    var index = 0
    var output = Data(capacity: (length * 5 / 8) | 0)
    
    for i in cleanedInput.indices {
        let char = try readChar(alphabet: alphabet, char: cleanedInput[i])
        value = (value << 5) | char
        bits += 5
        
        if bits >= 8 {
            output[index] = UInt8((value >> (bits - 8)) & 255)
            index += 1
            bits -= 8
        }
    }
    
    return output
    
}
