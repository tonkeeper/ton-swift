import Foundation
import CommonCrypto

public struct AES_CBC {
  enum Error: Swift.Error {
    case encryptionError(status: CCCryptorStatus)
    case decryptionError(status: CCCryptorStatus)
  }
  
  public let key: Data
  public let iv: Data
  
  public init(key: Data,
              iv: Data) {
    self.key = key
    self.iv = iv
  }
  
  public func decrypt(cipherData: Data) throws -> Data {
    var outputBuffer = Array<UInt8>(repeating: 0, count: cipherData.count)
    var numBytesDecrypted = 0
    
    let status = CCCrypt(CCOperation(kCCDecrypt),
                         CCAlgorithm(kCCAlgorithmAES),
                         CCOptions(kCCOptionPKCS7Padding),
                         Array(key),
                         kCCKeySizeAES256,
                         Array(iv),
                         Array(cipherData),
                         cipherData.count,
                         &outputBuffer,
                         cipherData.count,
                         &numBytesDecrypted)
    
    guard status == kCCSuccess else {
      throw Error.decryptionError(status: status)
    }
    
    
    let outputBytes = outputBuffer.prefix(numBytesDecrypted)
    return Data(outputBytes)
  }
  
  public func encrypt(data: Data) throws -> Data {
    var outputBuffer = Array<UInt8>(repeating: 0, count: data.count)
    var numBytesEncrypted = 0
    
    let status = CCCrypt(CCOperation(kCCEncrypt),
                         CCAlgorithm(kCCAlgorithmAES),
                         CCOptions(kCCOptionPKCS7Padding),
                         Array(key),
                         kCCKeySizeAES256,
                         Array(iv),
                         Array(data),
                         data.count,
                         &outputBuffer,
                         data.count,
                         &numBytesEncrypted)
    
    guard status == kCCSuccess else {
      throw Error.encryptionError(status: status)
    }
    let outputBytes = outputBuffer.prefix(numBytesEncrypted)
    return Data(outputBytes)
  }
}
