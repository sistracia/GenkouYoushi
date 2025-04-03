import Foundation

enum KanjiAPIClientError: Error {
    case invalidURL
    case missingData
}

extension KanjiAPIClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid URL.", comment: "")
        case .missingData:
            return NSLocalizedString("No data received.", comment: "")
        }
    }
}

struct Kanji {
    let kanji: String
    let strokeOrders: [String]
}

extension Kanji: Decodable {
    enum CodingKeys: String, CodingKey {
        case kanji = "kanji"
        case strokeOrders = "stroke_orders"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawKanji = try? values.decode(String.self, forKey: .kanji)
        var rawStrokeOrdersContainer = try values.nestedUnkeyedContainer(forKey: .strokeOrders)
        
        var rawStrokeOrders: [String] = []
        while !rawStrokeOrdersContainer.isAtEnd {
            if let rawStrokeOrdersContainer = try? rawStrokeOrdersContainer.decode(String.self) {
                rawStrokeOrders.append(rawStrokeOrdersContainer)
            }
        }
        
        guard let kanji = rawKanji,
              rawStrokeOrders.isEmpty
        else {
            throw KanjiAPIClientError.missingData
        }
        
        self.kanji = kanji
        self.strokeOrders = rawStrokeOrders
    }
}


actor KanjiAPIClient {
    private let baseURL: URL
    
    private let httpClient: any HTTPClient
    
    private lazy var jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        return jsonDecoder
    }()
    
    init(baseURL: URL, httpClient: any HTTPClient = URLSession.shared) {
        self.baseURL = baseURL
        self.httpClient = httpClient
    }
    
    private func request(endpoint: String) async throws -> Data {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw KanjiAPIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        let data = try await httpClient.httpData(for: request)
        return data
    }
    
    func getKanji(kanji: String, withNumber: Bool = false) async throws -> Kanji {
        let data = try await request(endpoint: "/kanji/\(kanji)?with_number=\(withNumber)")
        let response = try jsonDecoder.decode(Kanji.self, from: data)
        return response
    }
}
