import Foundation

enum NetworkError: Swift.Error {
    case badResponse
    case httpStatusCodeError(Int)

    var localizedDescription: String {
        switch self {
        case .badResponse:
            return "Unexpected response from server."
        case .httpStatusCodeError(let statusCode):
            return "Server returned HTTP error code \(statusCode)."
        }
    }
}
