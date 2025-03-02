import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct GenkouYoushiDocument: FileDocument {
    var pdfData: Data
    
    init() {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let pdf = renderer.pdfData { (context) in
            context.beginPage()
        }
        self.pdfData = pdf
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
