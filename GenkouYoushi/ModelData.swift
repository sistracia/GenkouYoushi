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
    
    init(kanjiAPIClient: KanjiAPIClient) {
        self.kanjiAPIClient = kanjiAPIClient
    }
}

