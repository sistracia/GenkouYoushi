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
    
    init(data: Data) {
        super.init(frame: .zero)
        
        let document = PDFDocument(data: data)!
        document.delegate = self
        
        self.autoScales = true
        self.pageOverlayViewProvider = self.overlay
        self.isInMarkupMode = true
        self.document = document
        self.data = data
    }
    
    func showToolPicker(isEnabled: Bool) {
        if (self.isToolPickerShow == isEnabled) {
            return
        }
        
        guard let page = currentPage as? MyPDFPage,
              let canvasView = overlay.pageToViewMapping[page]
        else { return }
        
        self.enablePageScroll(enabled: isEnabled)
        self.isToolPickerShow = isEnabled
        self.toolPicker.setVisible(isEnabled, forFirstResponder: canvasView)
        canvasView.isUserInteractionEnabled = isEnabled
        
        if (isEnabled) {
            self.toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        } else {
            self.toolPicker.removeObserver(canvasView)
            canvasView.resignFirstResponder()
        }
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
            if let page = document.page(at: i),
               let page = page as? MyPDFPage,
               let canvasView = page.canvasView {
                // For listen to `canvasViewDrawingDidChange`
                canvasView.delegate = delegate
            }
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
