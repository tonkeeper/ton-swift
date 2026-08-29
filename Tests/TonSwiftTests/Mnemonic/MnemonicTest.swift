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

  /// The generator must be able to pick every word in the 2048-word list,
  /// including the last one ("zoo", index 2047). A `% (words.count - 1)`
  /// reduction would make the final word unreachable and double-weight the
  /// second-to-last, so this asserts full-range coverage.
  func testMnemonicGeneratorCoversWholeWordList() throws {
    let wordList = Mnemonic.words
    XCTAssertEqual(wordList.count, 2048)

    // The last word must be a legal, generatable word — a validate() over a
    // 24-word phrase built to include it must not reject it on membership.
    let lastWord = try XCTUnwrap(wordList.last)
    XCTAssertTrue(wordList.contains(lastWord))

    // Sample enough generated mnemonics that, if any index were unreachable,
    // the observed distinct-word set would be capped below the full list.
    // 4000 * 24 ≈ 96k draws — the last index appearing at least once is
    // overwhelmingly likely once the modulo covers all 2048 slots.
    var seen = Set<String>()
    for _ in 0..<4000 {
      seen.formUnion(Mnemonic.mnemonicNew())
    }
    // Every generated word is a real list word (no off-by-one out of range).
    XCTAssertTrue(seen.isSubset(of: Set(wordList)))
    // And coverage reaches the tail of the list, which the old
    // `% (words.count - 1)` bug made impossible for the final index.
    XCTAssertTrue(seen.contains(lastWord),
                  "the last word in the list was never generated — modulo excludes the final index")
  }
}
