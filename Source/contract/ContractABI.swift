import Foundation

public struct ABIError {
    let message: String
}

public enum ABITypeRef {
    case simple(type: String, optional: Bool?, format: String?)
    case dict(format: String?, key: String, keyFormat: String?, value: String, valueFormat: String?)
}

public struct ABIField {
    let name: String
    let type: ABITypeRef
}

public struct ABIType {
    let name: String
    let header: Int?
    let fields: [ABIField]
}

public struct ABIArgument {
    let name: String
    let type: ABITypeRef
}

public struct ABIGetter {
    let name: String
    let methodId: Int?
    let arguments: [ABIArgument]?
    let returnType: ABITypeRef?
}

public enum ABIReceiverMessage {
    case typed(String)
    case any
    case empty
    case text(String?)
}

public struct ABIReceiver {
    let isInternalReceiver: Bool
    let message: ABIReceiverMessage
}

public struct ContractABI {
    let name: String?
    let types: [ABIType]?
    let errors: [Int: ABIError]?
    let getters: [ABIGetter]?
    let receivers: [ABIReceiver]?
}
