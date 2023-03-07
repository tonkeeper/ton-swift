import Foundation
import BigInt

public struct SenderArguments {
    let value: BigInt
    let to: Address
    let sendMode: SendMode?
    let bounce: Bool?
    let initState: (code: Cell?, data: Cell?)?
    let body: Cell?
}

public protocol Sender {
    var address: Address? { get }
    func send(args: SenderArguments)
}
