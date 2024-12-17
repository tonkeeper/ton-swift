import XCTest
@testable import TonSwift

final class MnemonicTest: XCTestCase {
    
    func testMnemonic() throws {
        let mnemonic = Mnemonic.mnemonicNew()
        XCTAssertTrue(Mnemonic.mnemonicValidate(mnemonicArray: mnemonic))
        
        // should validate mnemonic

        let mnemonicArray = "cluster notice abandon frost gospel boring element situate click mix vague replace imitate garment useful crater resource dose tenant theme foam ancient phrase slight".components(separatedBy: " ")
        XCTAssertTrue(Mnemonic.mnemonicValidate(mnemonicArray: mnemonicArray))
        XCTAssertFalse(Mnemonic.mnemonicValidate(mnemonicArray: mnemonicArray.dropLast()))
        
        // should create valid key pair
        
        let keyPair = try Mnemonic.anyMnemonicToPrivateKey(mnemonicArray: mnemonicArray)
        XCTAssertEqual(keyPair.publicKey.hexString, "34eb4b67d64f74d989ce2bc2e3dfddb7ed4cb0eec92f29fbecd05b1eabab0254")
        XCTAssertEqual(keyPair.privateKey.hexString, "c893fc0b676782a5c157ad8fddb389f75caba6eea1c198d8075a8a43afce70a934eb4b67d64f74d989ce2bc2e3dfddb7ed4cb0eec92f29fbecd05b1eabab0254")
    }
  
    
  func testIsMultiAccountSeedMnemonic() throws {
      let collisionMnemonic = "cluster notice abandon frost gospel boring element situate click mix vague replace imitate garment useful crater resource dose tenant theme foam ancient phrase slight".components(separatedBy: " ")
    
      XCTAssertFalse(Mnemonic.isMultiAccountSeed(mnemonicArray: collisionMnemonic))
    
      let multiAccountMnemonic = "execute peanut please demise thumb mango argue cloud reopen upset also dentist panic elite roast security pyramid extra boil execute lazy pledge notice check".components(separatedBy: " ")

      XCTAssertTrue(Mnemonic.isMultiAccountSeed(mnemonicArray: multiAccountMnemonic))
    
      let tonMnemonic = "item supply cover volcano satisfy window custom cupboard license dance record tissue gadget rural health blossom useless useless hungry brush grief stock reflect morning".components(separatedBy: " ")
    
      XCTAssertFalse(Mnemonic.isMultiAccountSeed(mnemonicArray: tonMnemonic))
  }
}
