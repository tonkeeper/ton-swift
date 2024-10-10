import XCTest
@testable import TonSwift

final class CommentEncryptionTests: XCTestCase {
  func testA() throws {
    let mnemonicA = Mnemonic.mnemonicNew()
    let keyPairA = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonicA)
    
    let mnemonicB = Mnemonic.mnemonicNew()
    let keyPairB = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonicB)
    
    let message = "this is the best message in the world"
    
    let encrypted = try CommentEncryptor(
      comment: message,
      senderPublicKey: keyPairA.publicKey,
      senderPrivateKey: keyPairA.privateKey,
      peerPublicKey: keyPairB.publicKey,
      senderAddress: try Address.parse("0:25603f6d7d3a1c6f981f02237c917150a6f2af971e83dd9e19605fa57a5d5b00")
    ).encrypt()
    
    let decrypted = try CommentDecryptor(
      privateKey: keyPairB.privateKey,
      publicKey: keyPairB.publicKey,
      cipherText: encrypted.hexString(),
      senderAddress: try Address.parse("0:25603f6d7d3a1c6f981f02237c917150a6f2af971e83dd9e19605fa57a5d5b00")
    ).decrypt()
    
    XCTAssertEqual(decrypted, message)
  }
}
