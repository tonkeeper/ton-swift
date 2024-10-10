import Foundation
import Clibsodium

public enum X25519 {
  enum Error: Swift.Error {
    case sharedSecretError(code: Int)
  }
  
  public struct PrivateKey: Key, Equatable, Codable {
    public let data: Data
    
    public init(data: Data) {
      self.data = data
    }
  }
  
  public struct PublicKey: Key, Equatable, Codable {
    public let data: Data
    
    public init(data: Data) {
      self.data = data
    }
  }
  
  static func getSharedSecret(privateKey: X25519.PrivateKey, publicKey: X25519.PublicKey) throws -> Data {
    var outputBuffer = Array<UInt8>(repeating: 0, count: .sharedSecretLength)
    try privateKey.data.withUnsafeBytes { bufferPointer in
      guard let privateKeyPointer = bufferPointer.baseAddress else { return }
      try publicKey.data.withUnsafeBytes { bufferPointer in
        guard let publicKeyPointer = bufferPointer.baseAddress else { return }
        let statusCode = crypto_scalarmult(&outputBuffer, privateKeyPointer, publicKeyPointer)
        guard statusCode == 0 else {
          throw Error.sharedSecretError(code: Int(statusCode))
        }
      }
    }
    return Data(outputBuffer)
  }
}

public extension X25519 {
  enum X25519ConversionError: Swift.Error {
    case publicKeyConversionFailed(code: Int)
    case privateKeyConversionFailed(code: Int)
  }
}

extension PublicKey {
  var toX25519: X25519.PublicKey {
    get throws {
      var outputBuffer = Array<UInt8>(repeating: 0, count: .publicKeyLength)
      try data.withUnsafeBytes { buffer in
        guard let pointer = buffer.baseAddress else { return }
        let statusCode = crypto_sign_ed25519_pk_to_curve25519(&outputBuffer, pointer)
        guard statusCode == 0 else {
          throw X25519.X25519ConversionError.publicKeyConversionFailed(code: Int(statusCode))
        }
      }
      return X25519.PublicKey(data: Data(outputBuffer))
    }
  }
}

extension PrivateKey {
  var toX25519: X25519.PrivateKey {
    get throws {
      var outputBuffer = Array<UInt8>(repeating: 0, count: .privateKeyLength)
      try data.withUnsafeBytes { buffer in
        guard let pointer = buffer.baseAddress else { return }
        let statusCode = crypto_sign_ed25519_sk_to_curve25519(&outputBuffer, pointer)
        guard statusCode == 0 else {
          throw X25519.X25519ConversionError.privateKeyConversionFailed(code: Int(statusCode))
        }
      }
      return X25519.PrivateKey(data: Data(outputBuffer))
    }
  }
}

private extension Int {
  static let privateKeyLength: Int = 32
  static let publicKeyLength: Int = 32
  static let sharedSecretLength: Int = 32
}
