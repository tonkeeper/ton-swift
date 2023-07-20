import Foundation

/// Various raw options for sending a message that affect error handling,
/// paying fees and sending the value.
/// This struct is a wrapper around sendmode flags that prevents accidental misuse.
public struct SendMode: RawRepresentable {
    /// Pays message fwd/ihr fees separately.
    /// If the flag is not set, those fees are subtracted from the message value.
    public let payMsgFees: Bool

    /// Ignores the errors in the action phase (due to invalid address, insufficient funds etc.)
    /// That is, if this message cannot be sent, this does not fail the rest of the transaction.
    public let ignoreErrors: Bool

    /// Options for sending the value.
    public let value: SendValueOptions

    init(payMsgFees: Bool = false, ignoreErrors: Bool = false, value: SendValueOptions = .messageValue) {
        self.payMsgFees = payMsgFees
        self.ignoreErrors = ignoreErrors
        self.value = value
    }

    /// Standard flags for the wallet is to pay msg fees on behalf of the sender
    /// and ignore errors so that sequence number can be bumped securely,
    /// so that bad transactions cannot be replayed indefinitely.
    static func walletDefault() -> Self {
        SendMode(payMsgFees: true, ignoreErrors: true)
    }

    // MARK: RawRepresentable

    public init?(rawValue: UInt8) {
        if rawValue & SendModeInvalidFlags > 0 {
            return nil // these bits are not used and must be set to zero
        }
        if let v = SendValueOptions(rawValue: rawValue) {
            self.value = v
        } else {
            return nil
        }
        self.payMsgFees = (rawValue & SendModePayMsgFees > 0)
        self.ignoreErrors = (rawValue & SendModeIgnoreErrors > 0)
    }

    public var rawValue: UInt8 {
        var m: UInt8 = value.rawValue
        if payMsgFees { m |= SendModePayMsgFees }
        if ignoreErrors { m |= SendModeIgnoreErrors }
        return m
    }
}
