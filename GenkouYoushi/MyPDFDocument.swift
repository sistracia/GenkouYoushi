import UIKit
import PDFKit
import UniformTypeIdentifiers

class MyPDFDocument: UIDocument {

    var document: PDFDocument? = nil
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        switch typeName {
        case "\(UTType.pdf)":
            guard let data = contents as? Data else { return }
            self.document = PDFDocument(data: data.isEmpty ? self.initStroke() : data)
        default:
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let document = self.document,
              let data = MyPDFAnnotation.addDrawAnnotations(from: document)
        else { return Data () }

        return data
    }
}

extension MyPDFDocument {
    func initStroke() -> Data {
        let pageMaxWidth: CGFloat = 612
        let pageMaxHeight: CGFloat = 792
        
        let blockStartHeight: CGFloat = pageMaxHeight -  pageMaxWidth
        let cellSize: CGFloat = 51
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageMaxWidth, height: pageMaxHeight))
        let pdf = renderer.pdfData { context in
            context.beginPage()
            
            let path = UIBezierPath()
            
            // Draw vertical lines
            for i in stride(from: cellSize, to: pageMaxWidth, by: cellSize) {
                path.move(to: CGPoint(x: i, y: blockStartHeight))
                path.addLine(to:  CGPoint(x: i, y: pageMaxHeight))
                path.stroke()
            }
            
            // Draw horizontal lines
            for i in stride(from: blockStartHeight, to: pageMaxHeight, by: cellSize) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to:  CGPoint(x: pageMaxHeight, y: i))
                path.stroke()
            }
        }
        
        return pdf
    }
}
