import XCTest
import BigInt

final class ParseDictTest: XCTestCase {
    
    private func storeBits(builder: Builder, src: String) throws -> Builder {
        for s in src {
            try builder.bits.write(bit: s != "0")
        }
        
        return builder
    }
    
    func int2bits(_ i: Int, bits: Int = 16) -> BitString {
        return try! Builder()
            .storeInt(i, bits: bits)
            .endCell()
            .bits
    }
    
    func testParseDict() throws {
        // should parse the one from documentation
        let root = try storeBits(builder: Builder(), src: "11001000")
            .storeRef(cell: try storeBits(builder: Builder(), src: "011000")
                .storeRef(cell: try storeBits(builder: Builder(), src: "1010011010000000010101001"))
                .storeRef(cell: try storeBits(builder: Builder(), src: "1010000010000000100100001"))
            )
            .storeRef(cell: try storeBits(builder: Builder(), src: "1011111011111101111100100001"))
            .endCell()
        
        let loaded = try parseDict(sc: try root.beginParse(), keySize: 16, extractor: { $0 })
        XCTAssertEqual(try loaded[int2bits(13)]?.bits.loadUint(bits: 16), 169)
        XCTAssertEqual(try loaded[int2bits(17)]?.bits.loadUint(bits: 16), 289)
        XCTAssertEqual(try loaded[int2bits(239)]?.bits.loadUint(bits: 16), 57121)
        
        // should parse with single node
        let root2 = try Cell(data: Data(hex: "a01f6e01b8f0a32c242ce41087ffee755406d9bcf9059a75e6b28d4af2a8250b73a8ee6b2800")!)
        
        let loaded2 = try parseDict(sc: try root2.beginParse(), keySize: 256, extractor: { $0 })
        XCTAssertEqual(try loaded2.keys.first!.toString(), "FB700DC7851961216720843FFF73AAA036CDE7C82CD3AF35946A579541285B9D")
        XCTAssertEqual(try loaded2.values.first?.asCell().bits.toString(), "4773594004_")
        
        //should parse dict with exotics
        let dict = Data(base64Encoded: "te6cckECMQEABTYAAhOCCc7v0txVpwSwAQIDEwEE53fpbirTglgEAwIISAEBs+lknRDMs3k2joGjp+jknI61P2rMabC6L/qACC9w7jkAAQhIAQGcUdBjRLK2XTGk56evuoGpCTwBOhaNJ3gUFm8TAe0n5QAyAxMBAye9rIc4cIC4MAYFCEgBAW8xXyW0o5rBLIX+pOz+eoPl5Z0fBZeD+gw+8nlzCIBhAAADEwEBQI3GZN/+jNgvBwgDEwEATAHi3hq0fjgKCQgISAEB7X4mvTbvptXZtPaqq5gTrwdCqEJEl390/UB0ycmJCL4AAAhIAQH6TA1tA7w5MqlUZE/iIYZlmhFY/0nMfG9YEH4IA4oG9AAmAxEA/JVwvbaVd7guDAsISAEB16y7YCM4yG1hDzXPs2L9dvwYsYEkdrb8qZoGeOZl/PUAAAIRAOC+0jznnr0oLQ0CEQDgeIc2I3nB6A8OCEgBAe5bbwbC8lILAkcW7BvTGqfH7ackw/xrJ+4xJ9g0lay7ACICDwDcWf0tZ7wILBACDwDPXe4GVoRIEhEISAEBpqnx4FY+VMV5fZOCgk11aYemGilh+4jfDQXGfVnuO2QAHwIPAMwQLzuW7ygrEwIPAMGD4CnDLugVFAhIAQHhkmjGsVW1E//8jS7VtFUP/nG+13eBz2DH8b6lkRkfowATAg8AwL3BnpH5iCoWAg8AwFv9OrsVqBgXCEgBAUnJQzkhkkoQxP70VqQNlWC2ClDLq6thxGgnH+VDOUIdABICDwDAI9NSaezIKRkCDQC0EKoS2YgbGghIAQEUW2BGLrIxcR0xUglz9exM5sN90zhfxgdRBW0FkjOQBQAPAg0ApaMONrGIHRwISAEB20MCSueWmfetSar0Li+5Q8Ip7t01JoPqgAJhVAvv4PEADAINAKFiMLr7SCgeAg0AoV/mfAxIJx8CDQCgRMc88eghIAhIAQHFrdac2QaoB3A0l38UmVSRNUC4pYwh2FyGJ5Vl+MyhJgAJAgkAbRF4aCYiAgkAZzzR6CQjCEgBAax1zsp9u3C3amDOdSJD9mQdDCqhiDj+ZgliaFHwLgWgAAIBj7rR38jjeSour5CAiFzP5jBGI24SWg7B0O37+3W43agB1e+xhmG5Sli1Zv3ZU7LzkGnD7l80gqgY14NkUTcQu0YAAC5TRp8sgyUISAEBnuyDAqn2pYKXQ/wsg9nT0mXlzYlz/XD92d92SJgRWv8AAQhIAQHEi2bfoY75oVrUbsi8DucSPG1oWEcd3KHUGYp0M+RQMQACCEgBAWJ+cuHH5x28R42OXHVN6a1Jf7VXJHmTxS88Gp/rZs2wAAIISAEBOz2DLgJl9RiydhyAtaSVoJad3MYUNnANbILzFnfSgEkADQhIAQHMnAtnlPhbBcz2DH0IRfSKuD1YfeBVgFaujjkW+iHqDgAPCEgBAVyyY7T30fyOwTmieJ8TthLedj5loRH+lxKqP5GbivrBABcISAEBuusLuLgfE7diC4/aes/bPk0SUgkgruJUU+h2pBoayZwAFwhIAQFmUFOfgo2uUi6cXR4FvV6TYWbPc7i/d5MmEQOA4FGbgQAbCEgBAV7HcGhkdhUswzXpHOx7WG6dvrqJjJdLMlC+kTQaJBqhACMISAEBG14jhyXXJ7RLRZCnKyrvsoR9OsBOvnfdOdK6ADqrS88AIQhIAQFZ+0nqF8AuEf14qz7cSjcXQjasTFC5jvk1aLELPzNMHAAnCEgBAdzBkxtJradUwhDmKe2fCZCcreVUbqwio3hW3tN6N2dBAhTWF3cC")!
        let cs = try Cell.fromBoc(src: dict).first!.beginParse()
        let loaded3 = try parseDict(sc: try cs.loadRef().beginParse(), keySize: 256, extractor: { $0 })
        XCTAssertEqual(try loaded3.keys.first!.toString(), "6D54D23BF91C6F2545D5F210110B99FCC608C46DC24B41D83A1DBF7F6EB71BB5")
        XCTAssertEqual(try loaded3.values.first?.asCell().bits.toString(), "003ABDF630CC37294B16ACDFBB2A765E720D387DCBE69055031AF06C8A26E21768C00005CA68D3E5906_")
    }
    
}
