import SwiftUI
import UniformTypeIdentifiers

struct GenkouYoushiDocument: FileDocument {
    var pdfData: Data
    
    init(pdfData: Data = Data()) {
        self.pdfData = pdfData
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

extension GenkouYoushiDocument {
    init() {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 72)
            ]
            let text = "Hello, PDF!"
            text.draw(at: CGPoint(x: 100, y: 100), withAttributes: attributes)
        }
        self.init(pdfData: data)
    }
}
