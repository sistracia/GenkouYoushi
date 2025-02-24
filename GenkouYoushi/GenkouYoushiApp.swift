import SwiftUI

@main
struct GenkouYoushiApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GenkouYoushiDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
