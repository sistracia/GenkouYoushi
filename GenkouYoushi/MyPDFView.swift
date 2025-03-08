import PDFKit
import PencilKit

class MyPDFView: PDFView  {
    private let overlay = MyPDFPageOverlay()
    private let toolPicker = PKToolPicker()
    private var isToolPickerShow = false
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoScales = true
        self.pageOverlayViewProvider = self.overlay
        self.isInMarkupMode = true
    }
    
    func loadPDF(document: PDFDocument) {
        document.delegate = self
        self.document = document
    }
    
    func showToolPicker(isEnabled: Bool) {
        if (self.isToolPickerShow || !isEnabled) {
            return
        }
        
        guard let page = currentPage as? MyPDFPage,
              let canvasView = overlay.pageToViewMapping[page]
        else { return }
        
        self.enablePageScroll(enabled: true)
        self.isToolPickerShow = true
        self.toolPicker.addObserver(canvasView.canvasView)
        self.toolPicker.setVisible(true, forFirstResponder: canvasView.canvasView)
        canvasView.canvasView.isUserInteractionEnabled = true
        canvasView.canvasView.becomeFirstResponder()
    }
    
    func enablePageScroll(enabled: Bool) {
        guard let subView = self.subviews.first,
              let subView = subView as? UIScrollView
        else { return }
        
        subView.isScrollEnabled = enabled
    }
    
    func setCanvasDelegate(_ delegate: PKCanvasViewDelegate) {
        guard let document = self.document else { return }
        
        for i in 0...document.pageCount-1 {
            if let page = document.page(at: i),
               let page = page as? MyPDFPage,
               let canvasView = page.canvasView?.canvasView {
                // For listen to `canvasViewDrawingDidChange`
                canvasView.delegate = delegate
            }
        }
    }
}

extension MyPDFView: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return MyPDFPage.self
    }
}
