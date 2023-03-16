import Foundation

let bounceableTag: UInt8 = 0x11
let nonBounceableTag: UInt8 = 0x51
let testFlag: UInt8 = 0x80


struct FriendlyAddress: Codable {
    let isTestOnly: Bool
    let isBounceable: Bool
    let workchain: Int8
    let hashPart: Data
    
    var address: Address {
        return Address(workchain: self.workchain, hash: self.hashPart)
    }
    
    init(string: String) throws {
        // Convert from url-friendly to true base64
        let string = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: string) else {
            throw TonError.custom("Address is not correctly encoded in Base64")
        }
        try self.init(data: data)
    }
    
    init(data: Data) throws {
        // 1byte tag + 1byte workchain + 32 bytes hash + 2 byte crc
        if data.count != 36 {
            throw TonError.custom("Unknown address type: byte length is not equal to 36")
        }
        
        let addr = data.subdata(in: 0..<34)
        let crc = data.subdata(in: 34..<36)
        let calcedCrc = addr.crc16()
        
        if calcedCrc[0] != crc[0] || calcedCrc[1] != crc[1] {
            throw TonError.custom("Invalid checksum: \(data)")
        }

        var tag = addr[0]
        if tag & testFlag != 0 {
            self.isTestOnly = true
            tag = tag ^ testFlag
        } else {
            self.isTestOnly = false
        }

        if tag != bounceableTag && tag != nonBounceableTag {
            throw TonError.custom("Unknown address tag")
        }

        self.isBounceable = (tag == bounceableTag)

        if addr[1] == 0xff {
            self.workchain = -1
        } else {
            self.workchain = Int8(addr[1])
        }
        self.hashPart = addr.subdata(in: 2..<34)
    }
}
