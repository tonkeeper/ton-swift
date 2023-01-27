Pod::Spec.new do |s|
  s.name             = 'TonSwift'
  s.version          = '0.0.1'
  s.homepage         = 'https://github.com/tonkeeper/ton-swift'
  s.source           = { :git => 'git@github.com:tonkeeper/ton-swift.git', :tag => s.version.to_s }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sergey Kotov' => 'thiskotov@yandex.ru' }
  s.summary          = 'Pure Swift implementation of TON core data structures: integers, bitstrings, cells, bags of cells, contracts and messages. The focus of the library is type safety and serialization. It does not support connectivity to TON p2p network, or Toncenter, Tonapi.io etc.'
  
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  
  s.source_files  = ["Source/*.{swift,h}", "Source/**/*.{swift,c,h}", "Source/**/**/*.{swift,c,h}"]

  s.dependency 'BigInt'
  
end
