import Foundation

enum SendMode: Int {
    case CARRY_ALL_REMAINING_BALANCE = 128
    case CARRY_ALL_REMAINING_INCOMING_VALUE = 64
    case DESTROY_ACCOUNT_IF_ZERO = 32
    case PAY_MSG_FEES_SEPARATELY = 1
    case IGNORE_ERRORS = 2
    case NONE = 0
}

