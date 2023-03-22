import Foundation
import BigInt

//
// Tree Build
//

func pad(_ src: String, _ size: Int) -> String {
    var src = src
    while src.count < size {
        src = "0" + src
    }
    
    return src
}

enum Node<T> {
    case fork(left: Edge<T>, right: Edge<T>)
    case leaf(value: T)
}

class Edge<T> {
    let label: String
    let node: Node<T>
    
    init(label: String, node: Node<T>) {
        self.label = label
        self.node = node
    }
}

func removePrefixMap<T>(_ src: [String: T], _ length: Int) -> [String: T] {
    if length == 0 {
        return src
    } else {
        var res: [String: T] = [:]
        for (k, d) in src {
            res[String(k.dropFirst(length))] = d
        }
        return res
    }
}

func forkMap<T>(_ src: [String: T]) throws -> (left: [String: T], right: [String: T]) {
    if src.isEmpty {
        throw TonError.custom("Internal inconsistency")
    }
    
    var left: [String: T] = [:]
    var right: [String: T] = [:]
    for (k, d) in src {
        if k.starts(with: "0") {
            left[String(k.dropFirst())] = d
        } else {
            right[String(k.dropFirst())] = d
        }
    }
    
    if left.isEmpty {
        throw TonError.custom("Internal inconsistency. Left empty.")
    }
    if right.isEmpty {
        throw TonError.custom("Internal inconsistency. Right empty.")
    }
    
    return (left, right)
}

func buildNode<T>(_ src: [String: T]) throws -> Node<T> {
    if src.isEmpty {
        throw TonError.custom("Internal inconsistency")
    }
    if src.count == 1 {
        return .leaf(value: Array(src.values)[0])
    }
    let (left, right) = try forkMap(src)
    
    return .fork(left: try buildEdge(left), right: try buildEdge(right))
}

func buildEdge<T>(_ src: [String: T]) throws -> Edge<T> {
    if src.isEmpty {
        throw TonError.custom("Internal inconsistency")
    }
    let label = findCommonPrefix(src: Array(src.keys))
    
    return Edge(label: label, node: try buildNode(removePrefixMap(src, label.count)))
}

func buildTree<T>(_ src: [BigInt: T], _ keyLength: Int) throws -> Edge<T> {
    // Convert map keys
    var converted: [String: T] = [:]
    for (k, v) in src {
        let padded = pad(String(k, radix: 2), keyLength)
        converted[padded] = v
    }

    // Calculate root label
    return try buildEdge(converted)
}

// Serialization
@discardableResult
func writeLabelShort(_ src: String, to builder: Builder) throws -> Builder {
    // Header
    try builder.bits.write(bit: false)

    try builder.store(Unary(src.count))

    // Value
    for c in src {
        try builder.bits.write(bit: c == "1")
    }
    
    return builder
}

func labelShortLength(_ src: String) -> Int {
    return 1 + src.count + 1 + src.count
}

@discardableResult
func writeLabelLong(src: String, keyLength: Int, to: Builder) throws -> Builder {
    // Header
    try to.bits.write(bit: true)
    try to.bits.write(bit: false)
    
    // Length
    let length = Int(ceil(log2(Double(keyLength + 1))))
    try to.storeUint(UInt64(src.count), bits: length)
    
    // Value
    for char in src {
        try to.bits.write(bit: char == "1")
    }
    return to
}

func labelLongLength(src: String, keyLength: Int) -> Int {
    return 1 + 1 + Int(ceil(log2(Double(keyLength + 1)))) + src.count
}

func writeLabelSame(value: Int, length: Int, keyLength: Int, to: Builder) throws {
    // Header
    try to.bits.write(bit: true)
    try to.bits.write(bit: true)
    // Value
    try to.bits.write(bit: value != 0)
    
    // Length
    let lenLen = Int(ceil(log2(Double(keyLength + 1))))
    try to.storeUint(UInt64(length), bits: lenLen)
}

func labelSameLength(keyLength: Int) -> Int {
    return 1 + 1 + 1 + Int(ceil(log2(Double(keyLength + 1))))
}

func isSame(src: String) -> Bool {
    if src.count == 0 || src.count == 1 {
        return true
    }
    
    for i in 1..<src.count {
        if src[src.index(src.startIndex, offsetBy: i)] != src[src.startIndex] {
            return false
        }
    }
    
    return true
}

enum LabelType {
    case short, long, same
}
func detectLabelType(src: String, keyLength: Int) -> LabelType {
    var kind: LabelType = .short
    var kindLength = labelShortLength(src)
    let longLength = labelLongLength(src: src, keyLength: keyLength)
    if longLength < kindLength {
        kindLength = longLength
        kind = .long
    }
    
    if isSame(src: src) {
        let sameLength = labelSameLength(keyLength: keyLength)
        if sameLength < kindLength {
            kindLength = sameLength
            kind = .same
        }
    }
    
    return kind
}

func writeLabel(src: String, keyLength: Int, to: Builder) throws {
    let type = detectLabelType(src: src, keyLength: keyLength)
    switch type {
    case .short:
        try writeLabelShort(src, to: to)
        
    case .long:
        try writeLabelLong(src: src, keyLength: keyLength, to: to)
        
    case .same:
        try writeLabelSame(value: src.first == "1" ? 1 : 0, length: src.count, keyLength: keyLength, to: to)
    }
}

func writeNode<T: DictionaryKeyTypes>(src: Node<T>, keyLength: Int, serializer: (T, Builder) throws -> Void, to: Builder) throws {
    switch src {
    case .fork(let left, let right):
        let leftCell = Builder()
        let rightCell = Builder()
        
        try writeEdge(src: left, keyLength: keyLength - 1, serializer: serializer, to: leftCell)
        try writeEdge(src: right, keyLength: keyLength - 1, serializer: serializer, to: rightCell)
        
        try to.storeRef(cell: leftCell)
        try to.storeRef(cell: rightCell)
        
    case .leaf(let value):
        try serializer(value, to)
    }
}

func writeEdge<T: DictionaryKeyTypes>(src: Edge<T>, keyLength: Int, serializer: (T, Builder) throws -> Void, to: Builder) throws {
    try writeLabel(src: src.label, keyLength: keyLength, to: to)
    try writeNode(src: src.node, keyLength: keyLength - src.label.count, serializer: serializer, to: to)
}

func serializeDict<T: DictionaryKeyTypes>(src: [BigInt: T], keyLength: Int, serializer: (T, Builder) throws -> Void, to: Builder) throws {
    let tree = try buildTree(src, keyLength)
    try writeEdge(src: tree, keyLength: keyLength, serializer: serializer, to: to)
}
