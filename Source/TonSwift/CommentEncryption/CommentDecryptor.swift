import Foundation

public struct CommentDecryptor {
  enum Error: Swift.Error {
    case incorrectCipherData
    case incorrectCipherDataLength
    case failedGetSharedSecret(error: Swift.Error)
    case incorrectEncryptedDataSize
    case incorrectHash
    case incorrectPrefixSize
  }
  
  private let privateKey: PrivateKey
  private let publicKey: PublicKey
  private let cipherText: String
  private let senderAddress: Address
  
  public init(privateKey: PrivateKey,
              publicKey: PublicKey,
              cipherText: String,
              senderAddress: Address) {
    self.privateKey = privateKey
    self.publicKey = publicKey
    self.cipherText = cipherText
    self.senderAddress = senderAddress
  }
  
  public func decrypt() throws -> String? {
    guard let cipherTextData = Data(hex: cipherText) else {
      throw Error.incorrectCipherData
    }
    
    let cipherTextBytes = [UInt8](cipherTextData)
    guard cipherTextBytes.count >= publicKey.data.count else {
      throw Error.incorrectCipherDataLength
    }
    let cipherTextPublicKeyBytes = Array(cipherTextBytes[0..<publicKey.data.count])
    let encryptedData = Array(cipherTextBytes[publicKey.data.count..<cipherTextBytes.count])
    guard encryptedData.count >= 16, encryptedData.count % 16 == 0 else {
      throw Error.incorrectEncryptedDataSize
    }
    
    let senderPublicKey = PublicKey(data: Data([UInt8](publicKey.data).enumerated().map { $0.element ^ cipherTextPublicKeyBytes[$0.offset] }))
    let sharedSecret: Data
    do {
      sharedSecret = try Ed25519.getSharedSecret(privateKey: privateKey, publicKey: senderPublicKey)
    } catch {
      throw Error.failedGetSharedSecret(error: error)
    }
  
    let msgKey = Data(Array(encryptedData[0..<16]))
    let data = Data(Array(encryptedData[16..<encryptedData.count]))
    
    let cbcStateSecret = HMAC_SHA512.hmacSha512(message: msgKey, key: sharedSecret)
    
    let aesKey = cbcStateSecret[0..<32]
    let iv = cbcStateSecret[32..<48]
    let decryptedData = try AES_CBC(key: aesKey, iv: iv).decrypt(cipherData: data)
  
    let salt = senderAddress.toFriendly(testOnly: false, bounceable: true).toString().data(using: .utf8) ?? Data()
    
    let decryptedDataHash = HMAC_SHA512.hmacSha512(message: decryptedData, key: salt)
    
    let encryptionMsgKey = decryptedDataHash[0..<16]
    guard encryptionMsgKey == msgKey else {
      throw Error.incorrectHash
    }
    
    let prefixLength = Int(decryptedData[0])
    guard prefixLength <= decryptedData.count && prefixLength >= 16 else {
      throw Error.incorrectPrefixSize
    }
    
    let decryptedMessage = decryptedData[prefixLength..<decryptedData.count]
    return String(data: decryptedMessage, encoding: .utf8)
  }
}
