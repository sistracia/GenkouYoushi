import Foundation

@MainActor @Observable
class ModelData {
    var serverState: ServerState = .idle
    
    enum ServerState: Equatable {
        case idle
        case loading
        case error(String)
    }
    
    let kanjiAPIClient: KanjiAPIClient
    
    init(kanjiAPIClient: KanjiAPIClient = KanjiAPIClient(baseURL: URL(string: "https://kanji-api.sistracia.com")!)) {
        self.kanjiAPIClient = kanjiAPIClient
    }
    
    
    func getKanji(kanji: String, withNumber: Bool = false) async -> Kanji? {
        var kanjiData: Kanji? = nil

        do {
            self.serverState = .loading
            kanjiData = try await kanjiAPIClient.getKanji(kanji: kanji, withNumber: withNumber)
            self.serverState = .idle
        } catch(let error) {
            self.serverState = .error(error.localizedDescription)
        }

        return kanjiData
    }
}

