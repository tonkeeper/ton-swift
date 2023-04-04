# TON Swift

Pure Swift implementation of TON core data structures: integers, bitstrings, cells, bags of cells, contracts and messages.

The focus of the library is type safety and serialization. It does not support connectivity to TON p2p network, or Toncenter, Tonapi.io etc.

# Current status

- [x] TON mnemonic and key pairs
- [x] Bitstrings
- [x] Cells
- [x] Hashmaps (aka “dictionary”)
- [x] Contract
- [x] StateInit
- [x] CommonMsgInfo
- [x] Send Flags
- [x] Text encoding (aka “snake data”)
- [x] Signatures
- [x] Standard wallets
- [ ] Data signatures [TEP/PR104](https://github.com/ton-blockchain/TEPs/pull/104)
- [ ] Subscriptions V1
- [ ] Jettons
- [ ] NFT
- [ ] TON.DNS

# Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

# Installation
Ready for use on iOS 13+.

### CocoaPods:
[CocoaPods](https://cocoapods.org) is a dependency manager. For usage and installation instructions, visit their website. To integrate using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'TonSwift', :git => 'git@github.com:tonkeeper/ton-swift.git', :branch => 'main'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but TonSwift does support its use on supported platforms. 

Once you have your Swift package set up, adding TonSwift as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/tonkeeper/ton-swift", .exact("1.0.0"))
]
```

# Authors

* [Sergey Kotov](kotov@tonkeeper.com)
* [Oleg Andreev](oleg@tonkeeper.com)

# License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0)
