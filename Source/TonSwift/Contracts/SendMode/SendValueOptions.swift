//
//  SendValueOptions.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

public enum SendValueOptions: RawRepresentable {
    /// Default choice: send the value specified for the message (minus the possible fees).
    case messageValue

    /// In addition to the specified value, message gets the remaining value from the incoming value.
    case addInboundValue

    /// Spend the entire balance (minus the fees).
    case sendRemainingBalance

    /// Spend the entire balance (minus the fees) and destroy the contract.
    case sendRemainingBalanceAndDestroy

    // MARK: RawRepresentable

    public typealias RawValue = UInt8

    public init?(rawValue: UInt8) {
        if rawValue & SendModeConflictingFlags == SendModeConflictingFlags {
            return nil // cannot set conflicting bits
        }
        if rawValue & SendModeSpendRemainingBalance > 0 {
            if rawValue & SendModeDestroyWhenEmpty > 0 {
                self = .sendRemainingBalanceAndDestroy
            } else {
                self = .sendRemainingBalance
            }
        } else if rawValue & SendModeAddRemainingInboundValue > 0 {
            self = .addInboundValue
        } else {
            self = .messageValue
        }
    }

    public var rawValue: UInt8 {
        switch self {
        case .messageValue: return 0
        case .addInboundValue: return SendModeAddRemainingInboundValue
        case .sendRemainingBalance: return SendModeSpendRemainingBalance
        case .sendRemainingBalanceAndDestroy: return SendModeSpendRemainingBalance | SendModeDestroyWhenEmpty
        }
    }
}
