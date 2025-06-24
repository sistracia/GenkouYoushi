import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct GenkouYoushiDocument: FileDocument {
    var pdfData: Data
    
    init(data: Data = Data()) {
        self.pdfData = data
    }
    
    static var readableContentTypes: [UTType] { [.pdf] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        pdfData = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: pdfData)
    }
}
