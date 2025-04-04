import Foundation

let validStatus = 200...299

protocol HTTPClient {
    func httpData(for: URLRequest) async throws -> Data
}

enum HTTPClientError: Error {
    case networkError
}

extension HTTPClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError:
            return NSLocalizedString("Network error.", comment: "")
        }
    }
}

extension URLSession: HTTPClient {
    func httpData(for url: URLRequest) async throws -> Data {
        guard let (data, response) = try await self.data(for: url, delegate: nil) as? (Data, HTTPURLResponse),
              validStatus.contains(response.statusCode)
        else {
            throw HTTPClientError.networkError
        }
        
        return data
    }
}
