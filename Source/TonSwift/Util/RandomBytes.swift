import Foundation

public struct RandomBytes {
  public enum Error: Swift.Error {
    case failedGenerate(statusCode: Int)
    case other
  }
  
  static func generate(length: Int) throws -> Data {
    var outputBuffer = Data(count: length)
    let resultCode = try outputBuffer.withUnsafeMutableBytes {
      guard let baseAddress = $0.baseAddress else { throw Error.other }
      return SecRandomCopyBytes(kSecRandomDefault, length, baseAddress)
    }
    guard resultCode == errSecSuccess else {
      throw Error.failedGenerate(statusCode: Int(resultCode))
    }
    return outputBuffer
  }
}
