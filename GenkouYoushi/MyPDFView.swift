import PDFKit
import PencilKit

class MyPDFView: PDFView  {
    private let overlay = MyPDFPageOverlay()
    private let toolPicker = PKToolPicker()
    private var isToolPickerShow = false
    var data = Data()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoScales = true
        self.pageOverlayViewProvider = self.overlay
        self.isInMarkupMode = true
    }
    
    func loadPDF(data: Data) {
        let document = PDFDocument(data: data)!
        document.delegate = self
        self.document = document
        self.data = data
    }
    
    func showToolPicker(isEnabled: Bool) {
        if (self.isToolPickerShow || !isEnabled) {
            return
        }
        
        guard let page = currentPage as? MyPDFPage,
              let canvasView = overlay.pageToViewMapping[page]
        else { return }
        
        self.isToolPickerShow = true
        self.toolPicker.addObserver(canvasView.canvasView)
        self.toolPicker.setVisible(true, forFirstResponder: canvasView.canvasView)
        canvasView.canvasView.isUserInteractionEnabled = true
        canvasView.canvasView.becomeFirstResponder()
    }    
}

extension MyPDFView: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return MyPDFPage.self
    }
}
