import PDFKit

class MyPDFView: PDFView, PDFDocumentDelegate {
    required init? (coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init (frame: CGRect) {
        super.init (frame: frame)
        self.autoScales = true
    }

    func loadPDF(_ document: PDFDocument) {
        document.delegate = self
        self.document = document
    }
    
    func classForPage () -> AnyClass {
        return MyPDFPage.self
    }
}
