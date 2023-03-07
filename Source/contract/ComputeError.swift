import Foundation

public struct ComputeError: Error {
    let code: Int
    let debugLogs: String?
    let logs: String?
}
