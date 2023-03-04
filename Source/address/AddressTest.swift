import XCTest

final class AddressTest: XCTestCase {

    func testAddress() throws {
        // should parse addresses in various forms
        let address1 = try Address.parseFriendly(source: "0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO")
        let address2 = try Address.parseFriendly(source: "kQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi47nL")
        let address3 = Address.parseRaw(source: "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        XCTAssertFalse(address1.isBounceable)
        XCTAssertTrue(address2.isBounceable)
        XCTAssertTrue(address1.isTestOnly)
        XCTAssertTrue(address2.isTestOnly)
        XCTAssertEqual(address1.address.workChain, 0)
        XCTAssertEqual(address2.address.workChain, 0)
        XCTAssertEqual(address3.workChain, 0)
        XCTAssertEqual(address1.address.hash, Data(hex: "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3"))
        XCTAssertEqual(address2.address.hash, Data(hex: "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3"))
        XCTAssertEqual(address3.hash, Data(hex: "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3"))
        XCTAssertEqual(address1.address.toRawString(), "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        XCTAssertEqual(address2.address.toRawString(), "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        XCTAssertEqual(address3.toRawString(), "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        
        // should serialize to friendly form
        let address = Address.parseRaw(source: "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        
        // Bounceable
        XCTAssertEqual(address.toString(), "EQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4wJB")
        XCTAssertEqual(address.toString(testOnly: true), "kQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi47nL")
        XCTAssertEqual(address.toString(urlSafe: false), "EQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi4wJB")
        XCTAssertEqual(address.toString(urlSafe: false, testOnly: true), "kQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi47nL")
        
        // Non-Bounceable
        XCTAssertEqual(address.toString(bounceable: false), "UQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi41-E")
        XCTAssertEqual(address.toString(testOnly: true, bounceable: false), "0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO")
        XCTAssertEqual(address.toString(urlSafe: false, bounceable: false), "UQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi41+E")
        XCTAssertEqual(address.toString(urlSafe: false, testOnly: true, bounceable: false), "0QAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi4+QO")
        
        // should implement equals
        let addr1 = Address.parseRaw(source: "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        let addr2 = Address.parseRaw(source: "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        let addr3 = Address.parseRaw(source: "-1:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3")
        let addr4 = Address.parseRaw(source: "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e5")
        XCTAssertEqual(addr1, addr2)
        XCTAssertEqual(addr2, addr1)
        XCTAssertNotEqual(addr2, addr4)
        XCTAssertNotEqual(addr2, addr3)
        XCTAssertNotEqual(addr4, addr3)
    }
}
