import Foundation

public enum Ed25519 {
  public enum Error: Swift.Error {
    case sharedSecretError(Swift.Error)
  }
  
  public static func getSharedSecret(privateKey: PrivateKey, publicKey: PublicKey) throws -> Data {
    do {
      let xPrivateKey = try privateKey.toX25519
      let xPublicKey = try publicKey.toX25519
      return try X25519.getSharedSecret(privateKey: xPrivateKey, publicKey: xPublicKey)
    } catch {
      throw Error.sharedSecretError(error)
    }
  }
}
