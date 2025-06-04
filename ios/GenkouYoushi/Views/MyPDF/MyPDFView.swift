import PDFKit
import PencilKit

class MyPDFView: PDFView  {
    private let overlay = MyPDFPageOverlay()
    var data = Data()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(data: Data) {
        super.init(frame: .zero)
        
        let document = PDFDocument(data: data)!
        document.delegate = self
        
        self.autoScales = true
        self.pageOverlayViewProvider = self.overlay
        self.isInMarkupMode = true
        self.document = document
        self.becomeFirstResponder()
        self.data = data
    }
    
    func showToolPicker(isEnabled: Bool) {
        self.enablePageScroll(enabled: isEnabled)
        
        for (_, canvas) in (self.overlay.pageToViewMapping)  {
            canvas.isUserInteractionEnabled = isEnabled
        }
        
        self.overlay.toolPicker.setVisible(isEnabled, forFirstResponder: self)
    }
    
    func enablePageScroll(enabled: Bool) {
        guard let subView = self.subviews.first,
              let subView = subView as? UIScrollView
        else { return }
        
        subView.isScrollEnabled = enabled
    }
    
    func setCanvasDelegate(_ delegate: PKCanvasViewDelegate?) {
        guard let document = self.document else { return }
        
        for i in 0...document.pageCount-1 {
            guard let page = document.page(at: i)
            else { return }
            
            guard let page = page as? MyPDFPage
            else { return }
            
            guard let canvasView = page.canvasView
            else { return }
            
            // For listen to `canvasViewDrawingDidChange`
            canvasView.delegate = delegate
        }
    }
    
    func getDataWithAnnotations() -> Optional<Data> {
        guard let document = self.document
        else { return nil }
        
        return MyPDFAnnotation.addDrawAnnotations(from: document)
    }
}

extension MyPDFView: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return MyPDFPage.self
    }
}
