//
//  SendModeTypes.swift
//  
//
//  Created by Kirill Kirilenko on 20/07/2023.
//

/// Pays message fwd/ihr fees separately.
/// If the flag is not set, those fees are subtracted from the message value.
/// IMPORTANT: do not use this flag directly, use `SendMode` type instead.
let SendModePayMsgFees: UInt8 = 1

/// Ignores the errors in the action phase (due to invalid address, insufficient funds etc.)
/// That is, if this message cannot be sent, this does not fail the rest of the transaction.
/// IMPORTANT: do not use this flag directly, use `SendMode` type instead.
let SendModeIgnoreErrors: UInt8 = 2

/// Account is destroyed when remaining balance is zero.
/// This flag comes into effect only when used together with `spendRemainingBalance`.
/// IMPORTANT: do not use this flag directly, use `SendMode` type instead.
let SendModeDestroyWhenEmpty: UInt8 = 32

/// In addition to the specified value, message gets the remaining value from the incoming value.
/// This flag cannot be used together with `spendRemainingBalance`.
/// IMPORTANT: do not use this flag directly, use `SendMode` type instead.
let SendModeAddRemainingInboundValue: UInt8 = 64

/// Message sends the entire remaining balance of the contract,
/// forwarding fees are subtracted from that amount.
/// This flag cannot be used together with `addRemainingInboundValue`.
/// IMPORTANT: do not use this flag directly, use `SendMode` type instead.
let SendModeSpendRemainingBalance: UInt8 = 128

let SendModeInvalidFlags: UInt8 = 4+8+16

let SendModeConflictingFlags: UInt8 = 128+64
