import Foundation

public struct CommentEncryptor {
  enum Error: Swift.Error {
    case commentIsEmpty
    case failedGetSharedSecret(error: Swift.Error)
    case incorrectDataSize
  }
  
  private let comment: String
  private let senderPublicKey: PublicKey
  private let senderPrivateKey: PrivateKey
  private let peerPublicKey: PublicKey
  private let senderAddress: Address
  
  public init(comment: String,
              senderPublicKey: PublicKey,
              senderPrivateKey: PrivateKey,
              peerPublicKey: PublicKey,
              senderAddress: Address) {
    self.comment = comment
    self.senderPublicKey = senderPublicKey
    self.senderPrivateKey = senderPrivateKey
    self.peerPublicKey = peerPublicKey
    self.senderAddress = senderAddress
  }
  
  public func encrypt() throws -> Data {
    guard !comment.isEmpty else {
      throw Error.commentIsEmpty
    }
    
    let commentData = comment.data(using: .utf8) ?? Data()
    let salt = senderAddress.toFriendly(testOnly: false, bounceable: true).toString().data(using: .utf8) ?? Data()
    
    let sharedSecret: Data
    do {
      sharedSecret = try Ed25519.getSharedSecret(privateKey: senderPrivateKey, publicKey: peerPublicKey)
    } catch {
      throw Error.failedGetSharedSecret(error: error)
    }
    
    let prefix = try getRandomPrefix(dataLength: commentData.count, minPadding: 16)
    let data = prefix + commentData
    
    guard data.count % 16 == 0 else { throw Error.incorrectDataSize }
    
    let dataHash = HMAC_SHA512.hmacSha512(message: data, key: salt)
    let msgKey = dataHash[0..<16]
    let cbcStateSecret = HMAC_SHA512.hmacSha512(message: msgKey, key: sharedSecret)
    
    let aesKey = cbcStateSecret[0..<32]
    let iv = cbcStateSecret[32..<48]
    let encrypted = try AES_CBC(key: aesKey, iv: iv).encrypt(data: data)
    
    let encryptedData = msgKey + encrypted
    
    let cipherTextPrefix = peerPublicKey.data.enumerated().map { $0.element ^ senderPublicKey.data[$0.offset] }
    let cipherTextData = Data(cipherTextPrefix + encryptedData)
    
    return cipherTextData
  }
  
  private func getRandomPrefix(dataLength: Int, minPadding: Int) throws -> Data {
    let prefixLength = ((minPadding + 15 + dataLength) & -16) - dataLength
    var prefix = try RandomBytes.generate(length: prefixLength)
    prefix[0] = withUnsafeBytes(of: prefixLength.littleEndian, Array.init)[0]
    return prefix
  }
}
