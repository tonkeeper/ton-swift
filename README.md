# TON Swift

Pure Swift implementation of TON core data structures: integers, bitstrings, cells, bags of cells, contracts and messages.

The focus of the library is type safety and serialization. It does not support connectivity to TON p2p network, or Toncenter, Tonapi.io etc.

# Current status

- [x] TON mnemonic and key pairs
- [x] Bitstrings
- [x] Cells
- [x] Hashmap (aka “dictionary”)
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

# Authors

* [Sergey Kotov](kotov@tonkeeper.com)
* [Oleg Andreev](oleg@tonkeeper.com)

# License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0)
