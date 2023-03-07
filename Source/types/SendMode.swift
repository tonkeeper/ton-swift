import Foundation

enum SendMode: Int {
    case CARRRY_ALL_REMAINING_BALANCE = 128
    case CARRRY_ALL_REMAINING_INCOMING_VALUE = 64
    case DESTROY_ACCOUNT_IF_ZERO = 32
    case PAY_GAS_SEPARATLY = 1
    case IGNORE_ERRORS = 2
    case NONE = 0
}
